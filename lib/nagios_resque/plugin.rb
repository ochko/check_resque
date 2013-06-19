module NagiosResque
  class Plugin < NagiosPlugin::Plugin
    include NagiosPlugin::DefaultOptions

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

      @service = Check.new(@options)

      ENV['PATH'] = "/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
    end

    def check
      if @service.critical?
        critical @service.critical_message
      elsif @service.warning?
        warning @service.warning_message
      else
        ok @service.ok_message
      end
    ensure
      @service.requeue
    end
  end
end
