module NagiosResque
  class Check
    def initialize(options)
      @host      = options[:host]      || "localhost"
      @port      = options[:port]      || 6379
      @job       = options[:job]       || 'NagiosResque::Job'
      @namespace = options[:namespace]
      @warning   = options[:warn]
      @critical  = options[:crit]

      @redis = ResqueRedis.new(:host => @host, :port => @port, :namespace => @namespace)
    end

    # It is just (:class => @job, :args => []).to_json
    # Don't want to depend on resque gem which itself has many dependecies
    def payload
      %Q({"class":"#{@job}","args":[]})
    end

    def requeue
      @redis.sadd 'queues', 'high'
      @redis.lrem 'queue:high', 0, payload
      @redis.rpush 'queue:high', payload
    end

    def warning?
      @warning && (passed_time.nil? || @warning.include?(passed_time))
    end

    def critical?
      return true unless passed_time
      @critical && (passed_time.nil? || @critical.first < passed_time)
    end

    def last_run_at
      if time = @redis.get(NAGIOS_RESQUE_TIMESTAMP_KEY)
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

    class ResqueRedis
      def initialize(options)
        @namespace = ['resque', options.delete(:namespace)].compact.join(':')
        @redis = Redis.new options.merge(:thread_safe => true)
      end

      def namespaced(key)
        "#{@namespace}:#{key}"
      end

      def get(key)
        @redis.get namespaced(key)
      end
      def sadd(key, value)
        @redis.sadd namespaced(key), value
      end
      def lrem(key, count, value)
        @redis.lrem namespaced(key), count, value
      end
      def rpush(key, value)
        @redis.rpush namespaced(key), value
      end
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
