require "sinatra"
require "rest_client"
require "json"
require "contribution-checker"

CLIENT_ID = ENV["GITHUB_CLIENT_ID"]
CLIENT_SECRET = ENV["GITHUB_CLIENT_SECRET"]

use Rack::Session::Pool, :cookie_only => false

def authenticated?
  session[:access_token]
end

def authenticate!
  redirect "https://github.com/login/oauth/authorize?scope=user:email&client_id=#{CLIENT_ID}"
end

get "/" do
  if !authenticated?
    authenticate!
  else
    access_token = session[:access_token]

    begin
      auth_result = RestClient.get(
        "https://api.github.com/user",
        { :params => { :access_token => access_token}, :accept => :json })
    rescue => e
      # Token has been revoked. Invalidate the token in the session.
      session[:access_token] = nil
      return authenticate!
    end

    auth_result = JSON.parse(auth_result)
    if params[:url]
      checker = ContributionChecker::Checker.new \
        :access_token => access_token,
        :commit_url => params[:url]

      begin
        result = checker.check
        result[:commit_url] = params[:url]
      rescue ContributionChecker::InvalidCommitUrlError => err
        return erb :index, :locals => { :error_message => err }
      end
      erb :result, :locals => result
    else
      erb :index
    end
  end
end

get "/callback" do
  session_code = request.env["rack.request.query_hash"]["code"]
  result = RestClient.post(
    "https://github.com/login/oauth/access_token",
    { :client_id => CLIENT_ID,
      :client_secret => CLIENT_SECRET,
      :code => session_code },
    :accept => :json)
  session[:access_token] = JSON.parse(result)["access_token"]
  redirect "/"
end
