module NagiosResque
  class Check
    def initialize(options)
      @host      = options[:host]      || "localhost"
      @port      = options[:port]      || 6379
      @namespace = options[:namespace] || "resque"
      @job       = options[:job]       || 'NagiosResque::Job'
      @warning   = options[:warn]
      @critical  = options[:crit]

      Resque.redis = "#{@host}:#{@port}/#{@namespace}"
    end

    def warning?
      @warning && (passed_time.nil? || @warning.include?(passed_time))
    end

    def critical?
      return true unless passed_time
      @critical && (passed_time.nil? || @critical.first < passed_time)
    end

    def last_run_at
      if time = Resque.redis.get(NAGIOS_RESQUE_TIMESTAMP_KEY)
        Integer(time)
      end
    end

    def passed_time
      # need to cache because there is small time difference between checks
      return @passed_time if defined?(@passed_time)
      @passed_time =
        if time = last_run_at
          Integer(Time.now - time)
        else
          nil
        end
    end

    def requeue
      Resque::Job.destroy(:high, @job)
      Resque::Job.create(:high, @job)
    end

    def ok_message
      "last run at #{Time.at(last_run_at).strftime('%Y-%m-%d %H:%M:%S %z')}"
    end

    def warning_message
      "haven't run in #{@warning.last} seconds"
    end

    def critical_message
      "haven't run in #{@critical.first} seconds"
    end
  end
end
