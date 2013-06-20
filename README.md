# Nagios plugin for Resque

It checks resque by putting given job in high queue and expects the job will update key with timestamp.

```$ check_resque -n 'resque:production' -j 'NagiosResque::Job'```

## Default Job

Job need update NagiosResque::NAGIOS_RESQUE_TIMESTAMP_KEY key with timestamp.

```ruby
module NagiosResque
  class Job
    def self.perform
      Resque.redis.set(NAGIOS_RESQUE_TIMESTAMP_KEY, Time.now.to_i)
    end
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