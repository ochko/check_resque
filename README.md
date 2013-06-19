# Nagios plugin for Resque

It checks resque by putting given job in high queue and expects the job will update key with timestamp.

```$ ruby check_resque.rb -n production -j ResqueNagiosJob -k 'resque:job:nagios:processed:time'```

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
    -p, --port number                redis server port
    -n, --namespace name             redis namespace
    -j, --job name                   resque job name
    -k, --key name                   redis key for timestamp

Default options:

    -h, --help                       Display this help.
    -V, --version                    Print version.
    -w, --warn <n:m>                 Warning threshold.
    -c, --crit <n:m>                 Critical threshold.
```