# encoding: UTF-8
require 'date'

Gem::Specification.new do |s|
  s.name     = "onesignal-cli"
  s.version  = '1.0.0'
  s.date     = Date.today
  s.license  = "MIT"
  s.email    = [""]
  s.homepage = "https://onesignal.com"
  s.authors  = [""]

  s.summary     = "OneSignal CLI"
  s.description = ""

  s.files = Dir["lib/**/*.rb"] + %w{ bin/onesignal }

  s.executables   = %w{ onesignal }
  s.require_paths = %w{ lib }

#   s.add_runtime_dependency 'rspec'
  s.add_runtime_dependency 'clamp'
  s.add_runtime_dependency 'xcodeproj'

  s.required_ruby_version = '>= 2.4'
end