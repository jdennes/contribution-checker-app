require "sinatra"
require "sinatra/json"
require "contribution-checker"
require "octokit"

CLIENT_ID = ENV["GITHUB_CLIENT_ID"]
CLIENT_SECRET = ENV["GITHUB_CLIENT_SECRET"]

use Rack::Session::Pool, :cookie_only => false

# Ask the user to authorise the app.
def authenticate!
  redirect "https://github.com/login/oauth/authorize?scope=user:email&client_id=#{CLIENT_ID}"
end

# Check whether the user has an access token.
def authenticated?
  session[:access_token]
end

# Check whether the user's access token is valid.
def check_access_token
  @access_token = session[:access_token]

  begin
    @client = Octokit::Client.new :access_token => @access_token
    @user = @client.user
  rescue => e
    # The token has been revoked, so invalidate the token in the session.
    session[:access_token] = nil
    authenticate!
  end
end

# Get the user's recent commits from their public activity feed.
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
  commits.take 15
end

# Serve the main page.
get "/" do
  authenticate! if !authenticated?
  check_access_token
  erb :index, :locals => { :recent_commits => recent_commits }
end

# Respond to requests to check a commit. The commit URL is included in the
# url param.
post "/" do
  authenticate! if !authenticated?
  check_access_token
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

# Handle the redirect from GitHub after someone authorises the app.
get "/callback" do
  session_code = request.env["rack.request.query_hash"]["code"]
  result = Octokit.exchange_code_for_token \
    session_code, CLIENT_ID, CLIENT_SECRET, :accept => "application/json"
  session[:access_token] = result.access_token
  redirect "/"
end
