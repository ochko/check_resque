# -*- encoding: utf-8 -*-

$:.unshift File.expand_path("../lib", __FILE__)

require 'nagios_resque/version'

Gem::Specification.new do |s|
  s.name = "check_resque_paranoid"

  s.version = NagiosResque::VERSION

  s.homepage = "https://github.com/ochko/check_resque_paranoid"

  s.summary = "Nagios plugin for Resque"

  s.description = <<-EOS
    A paranoid nagios plugin for checking resque jobs actually being
    queued, processed in given time. It queues simple job, then later
    checks if the job is processed and updated timestamp in redis.
  EOS

  s.authors     = ["Lkhagva Ochirkhuyag"]

  s.email       = ["ochkoo@gmail.com"]

  s.files       = `git ls-files`.split("\n")

  s.executables = %w[check_resque]

  s.add_dependency('redis')
  s.add_dependency('nagiosplugin')
end
