#!__RUBY__

require 'rubygems'
require 'nagiosplugin'
require 'nagiosplugin/default_options'
require 'resque'

class NagiosResquePlugin < NagiosPlugin::Plugin
  include NagiosPlugin::DefaultOptions
  VERSION = 0.1

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
      opts.on("-P", "--port number", Integer, "redis server port") do |port|
        @options[:port] = port
      end
      opts.on("-N", "--namespace name", String, "redis namespace") do |namespace|
        @options[:namespace] = namespace
      end
      opts.on("-J", "--job name", String, "resque job name") do |job|
        @options[:job] = job
      end
      opts.on("-K", "--key name", String, "redis key for timestamp") do |key|
        @options[:key] = key
      end
      opts.on("-T", "--tolerance time", Integer, "tolerance time in seconds") do |tolerance|
        @options[:tolerance] = tolerance
      end

      yield(opts) if block_given?

      begin
        opts.parse!(args)
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
      @tolerance = options[:tolerance] || 600

      Resque.redis = "#{@host}:#{@port}/resque:#{@namespace}"
    end

    def timestamp
      if time = Resque.redis.get(@key)
        Time.at(time.to_i)
      else
        Time.now - 3600*24 # 24 hours
      end
    end
    def overdue?
      timestamp <= tolerance
    end
    def requeue
      Resque::Job.destroy(:high, @job)
      Resque::Job.create(:high, @job)
    end
    def tolerance
      Time.now - @tolerance
    end
    def success_message
      "#{@job} was run last time at #{timestamp}"
    end
    def failure_message
      "#{@job} is not being processed in #{@tolerance} seconds"
    end
  end

  def check
    if @resque_check.overdue?
      critical @resque_check.failure_message
    else
      ok @resque_check.success_message
    end
  ensure
    @resque_check.requeue
  end
end

NagiosResquePlugin.run(*ARGV)
