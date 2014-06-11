require "sinatra"
require "rest_client"
require "json"
require "sinatra/json"
require "contribution-checker"
require "octokit"

CLIENT_ID = ENV["GITHUB_CLIENT_ID"]
CLIENT_SECRET = ENV["GITHUB_CLIENT_SECRET"]

use Rack::Session::Pool, :cookie_only => false

def authenticated?
  session[:access_token]
end

def authenticate!
  redirect "https://github.com/login/oauth/authorize?scope=user:email&client_id=#{CLIENT_ID}"
end

def recent_commits
  public_events = @client.user_public_events @user[:login]
  public_events.select! { |e| e[:type] == "PushEvent" }
  commits = []
  public_events.each do |e|
    e[:payload][:commits].each do |c|
      c[:html_url] = "https://github.com/#{e[:repo][:name]}/commit/#{c[:sha]}"
      c[:shortcut] = "#{e[:repo][:name]}@#{c[:sha][0..7]}"
    end
    commits.concat e[:payload][:commits]
  end
  commits.take 5
end

get "/" do
  if !authenticated?
    authenticate!
  else
    @access_token = session[:access_token]

    begin
      @client = Octokit::Client.new :access_token => @access_token
      @user = @client.user
    rescue => e
      # Token has been revoked. Invalidate the token in the session.
      session[:access_token] = nil
      return authenticate!
    end
    erb :index, :locals => { :recent_commits => recent_commits }
  end
end

post "/" do
  if !authenticated?
    authenticate!
  else
    @access_token = session[:access_token]

    begin
      @client = Octokit::Client.new :access_token => @access_token
      @user = @client.user
    rescue => e
      # Token has been revoked. Invalidate the token in the session.
      session[:access_token] = nil
      return authenticate!
    end
  end
  check
end

def check
  checker = ContributionChecker::Checker.new \
    :access_token => @access_token,
    :commit_url => params[:url]

  begin
    result = checker.check
    result[:commit_url] = params[:url]
  rescue ContributionChecker::InvalidCommitUrlError => err
    return json :error_message => err
  end
  json result
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
