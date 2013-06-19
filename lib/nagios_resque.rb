require 'resque'
require 'nagiosplugin'
require 'nagiosplugin/default_options'
require 'nagios_resque/version'
require 'nagios_resque/job'
require 'nagios_resque/check'
require 'nagios_resque/plugin'

module NagiosResque
  NAGIOS_RESQUE_TIMESTAMP_KEY = 'resque:job:monitor:nagios:time'
end

NagiosPlugin::DefaultOptions::VERSION = NagiosResque::VERSION
