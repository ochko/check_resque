# Nagios plugin for Resque

It checks resque by putting given job in high queue and expects the job will update key with timestamp.

```$ ruby check_resque.rb -N production -T 60 -J ResqueNagiosJob -K 'resque:job:nagios:processed:time'```

## Example Job

```ruby
class ResqueNagiosJob
  REDIS_KEY = 'resque:job:nagios:processed:time'

  def self.perform
    Resque.redis.set(REDIS_KEY, time.to_i)
  end
end
```

## Options

```
Usage: check_resque [options]
    -H, --host hosname               redis server
    -P, --port number                redis server port
    -N, --namespace name             redis namespace
    -J, --job name                   resque job name
    -K, --key name                   redis key for timestamp
    -T, --tolerance time             tolerance time in seconds

Default options:

    -h, --help                       Display this help.
    -V, --version                    Print version.
    -w, --warn <n:m>                 Warning threshold.
    -c, --crit <n:m>                 Critical threshold.
```