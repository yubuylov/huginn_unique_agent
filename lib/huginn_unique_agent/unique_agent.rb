require 'redis'
require 'redis-namespace'

module Agents
  class UniqueAgent < Agent
    include FormConfigurable
    cannot_be_scheduled!
    can_order_created_events!

    description <<-MD
      The UniqueAgent receives a stream of events and remits the event if it is not a duplicate.

      `property` the value that should be used to determine the uniqueness of the event (empty to use the whole payload)

      `lookback` amount of past Events to compare the value to (0 for unlimited)

      `expected_update_period_in_days` is used to determine if the Agent is working.
    MD

    event_description <<-MD
      The UniqueAgent just reemits events it received.
    MD

    def default_options
      {
          'property' => '{{value}}',
          'lookback' => 1000,
          'expected_update_period_in_days' => 1
      }
    end

    form_configurable :property
    form_configurable :lookback
    form_configurable :expected_update_period_in_days

    after_initialize :initialize_redis

    def memory=(value)
      @redis.del("unique#{id}") if value == {}
      self[:memory] = value
    end

    def memory
      {
          'length' => @redis.zcount(redis_key, 0, 0),
          'keys' => @redis.zrange(redis_key, 0, -1)
      }
    end

    def initialize_redis
      host = ENV['UNIQUE_REDIS_HOST'].presence || "127.0.0.1"
      port = ENV['UNIQUE_REDIS_PORT'].presence || "6379"
      ns = ENV['UNIQUE_REDIS_NS'].presence || "huginn"
      @redis = Redis::Namespace.new(ns, :redis => Redis.new(host: host, port: port))
    end

    def validate_options
      unless options['lookback'].present? && options['expected_update_period_in_days'].present?
        errors.add(:base, "The lookback and expected_update_period_in_days fields are all required.")
      end
    end

    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        handle(interpolated(event), event)
      end
    end

    private

    def handle(opts, event = nil)
      property = get_hash(options['property'].blank? ? JSON.dump(event.payload) : opts['property'])
      if is_unique?(property)
        created_event = create_event :payload => event.payload
        log("Propagating new event as '#{property}' is a new unique property.", :inbound_event => event)
        check_memory(opts['lookback'].to_i)
      else
        log("Not propagating as incoming event is a duplicate.", :inbound_event => event)
      end
    end

    def get_hash(property)
      if property.to_s.length > 10
        Zlib::crc32(property).to_s
      else
        property
      end
    end

    def redis_key
      "uniq#{id}"
    end

    def is_unique?(property)
      @redis.zadd(redis_key, 0, property)
    end

    def check_memory(amount)
      length = @redis.zcount(redis_key, 0, 0)
      if amount != 0 && length == amount
        val = @redis.zrange(redis_key, 0, 0)
        @redis.zrem(redis_key, val)
      end
    end
  end
end
