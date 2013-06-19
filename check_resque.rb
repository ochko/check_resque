
require 'rubygems'
require 'nagiosplugin'
require 'nagiosplugin/default_options'
require 'resque'

class NagiosResquePlugin < NagiosPlugin::Plugin
  include NagiosPlugin::DefaultOptions

  NagiosPlugin::DefaultOptions::VERSION = 0.1

  class << self
    def run(*args)
      self.new(*args).run
    end
  end

  def parse_options(*args)
    @options = {}
    OptionParser.new do |opts|
      opts.on("-H", "--host hosname", String, "redis server") do |host|
        @options[:host] = host
      end
      opts.on("-p", "--port number", Integer, "redis server port") do |port|
        @options[:port] = port
      end
      opts.on("-n", "--namespace name", String, "redis namespace") do |namespace|
        @options[:namespace] = namespace
      end
      opts.on("-j", "--job name", String, "resque job name") do |job|
        @options[:job] = job
      end
      opts.on("-k", "--key name", String, "redis key for timestamp") do |key|
        @options[:key] = key
      end

      yield(opts) if block_given?

      begin
        opts.parse!(args)

        if @options[:warn].nil? && @options[:crit].nil?
          @options[:crit] ||= (600..600)
        end

        if !@options[:warn].nil? && !@options[:crit].nil?
          if @options[:warn].last > @options[:crit].first
            unknown "Critical and Warning thresholds shouldn't overlap"
          end
        end
        @options
      rescue => e
        unknown "#{e}\n\n#{opts}"
      end
    end
  end

  def service
    'Resque'
  end

  def initialize(*args)
    parse_options(*args, &default_options)

    @resque_check = ResqueCheck.new(@options)

    ENV['PATH'] = "/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
  end

  class ResqueCheck
    def initialize(options)
      @host      = options[:host]      || "localhost"
      @port      = options[:port]      || 6379
      @namespace = options[:namespace] || "production"
      @job       = options[:job]       || 'ResqueMonitorJob'
      @key       = options[:key]       || 'resque:job:monitor:time'
      @warning   = options[:warn]
      @critical  = options[:crit]

      Resque.redis = "#{@host}:#{@port}/resque:#{@namespace}"
    end

    def warning?
      @warning && (passed_time.nil? || @warning.include?(passed_time))
    end

    def critical?
      return true unless passed_time
      @critical && (passed_time.nil? || @critical.first < passed_time)
    end

    def last_run_at
      if time = Resque.redis.get(@key)
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

  def check
    if @resque_check.critical?
      critical @resque_check.critical_message
    elsif @resque_check.warning?
      warning @resque_check.warning_message
    else
      ok @resque_check.ok_message
    end
  ensure
    @resque_check.requeue
  end
end

NagiosResquePlugin.run(*ARGV)
