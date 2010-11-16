# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sinatra/cli/version"

Gem::Specification.new do |s|
  s.name        = "sinatra-cli"
  s.version     = Sinatra::CLI::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["David Dollar"]
  s.email       = ["ddollar@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/sinatra-cli"
  s.summary     = %q{Extension for building CLIs with Sinatra}
  s.description = s.summary

  s.files         = %x{ git ls-files }.split("\n").select { |f| f.match(%r{^(README|bin/|data/|ext/|lib/|spec/|test/)}) }
  s.require_paths = ["lib"]
end
