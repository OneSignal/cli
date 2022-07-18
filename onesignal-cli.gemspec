# encoding: UTF-8
require 'date'

Gem::Specification.new do |s|
  s.name     = "onesignal-cli"
  s.version  = '1.0.0'
  s.date     = Date.today
  s.license  = "MIT"
  s.email    = ["elliot@onesignal.com", "josh@onesignal.com"]
  s.homepage = "https://onesignal.com"
  s.authors  = ["Josh Kasten", "Elliot Mawby"]

  s.summary     = "OneSignal's Ruby CLI"
  s.description = "Ruby Gem for OneSignal's Ruby Command Line Interface."

  s.files = Dir["lib/**/*.rb"] + %w{ bin/onesignal } + Dir["include/**/*"]

  s.executables   = %w{ onesignal }
  s.require_paths = %w{ lib }

  s.add_runtime_dependency 'clamp'
  s.add_runtime_dependency 'xcodeproj'

  s.required_ruby_version = '>= 2.4'
end