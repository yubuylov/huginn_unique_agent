require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::UniqueAgent do
  before(:each) do
    @valid_options = Agents::UniqueAgent.new.default_options
    @checker = Agents::UniqueAgent.new(:name => "UniqueAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  describe '#working?' do
    it 'checks if events have error' do
      @checker.error "oh no!"
      expect(@checker.reload).not_to be_working # There is a recent error
    end
  end

end
