# UniqieAgent

Redis based Unique agent for huginn.

## Installation

Add `huginn_unique_agent` to your Huginn's `ADDITIONAL_GEMS` configuration:

[Docker installation](https://github.com/cantino/huginn/tree/master/docker):
```yaml
# docker env
environment:
  ADDITIONAL_GEMS: 'huginn_unique_agent(git: https://github.com/yubuylov/huginn_unique_agent.git)'
  UNIQUE_REDIS_HOST: '127.0.0.1'
  UNIQUE_REDIS_PORT: '6379'
  UNIQUE_REDIS_ns: 'huginn'

```

[Local installation](https://github.com/cantino/huginn#local-installation):
```ruby 
# .env (Local huginn installation)
ADDITIONAL_GEMS=huginn_unique_agent(github: yubuylov/huginn_unique_agent)
```

