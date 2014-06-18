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
require "webmock/rspec"

WebMock.disable_net_connect! :allow => "coveralls.io"

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new "#{fixture_path}/#{file}"
end

def json_response(file)
  {
    :body => fixture(file),
    :headers => {
      :content_type => "application/json; charset=utf-8"
    }
  }
end
