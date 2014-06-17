require "simplecov"
require "coveralls"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

$:.unshift File.expand_path('..', __FILE__)

ENV["GITHUB_CLIENT_ID"] = "myclientid"
ENV["GITHUB_CLIENT_SECRET"] = "myclientsecret"

require "./app"
require "rspec"
require "rack/test"

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end
