module NagiosResque
  class Job
    def self.perform
      Resque.redis.set(NAGIOS_RESQUE_TIMESTAMP_KEY, Time.now.to_i)
    end
  end
end
