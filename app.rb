require "sinatra"
require "sinatra/json"
require "contribution-checker"
require "octokit"

CLIENT_ID = ENV["GITHUB_CLIENT_ID"]
CLIENT_SECRET = ENV["GITHUB_CLIENT_SECRET"]

enable :sessions
set :session_secret, ENV["SESSION_SECRET"]

configure do
  require "newrelic_rpm" if production?
end

# Ask the user to authorise the app.
def authenticate!
  redirect "https://github.com/login/oauth/authorize?scope=user:email,read:org&client_id=#{CLIENT_ID}"
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

# Wrapper route for redirecting the user to authorise the app.
get "/auth" do
  authenticate!
end

# Serve the main page.
get "/" do
  if !authenticated?
    erb :how, :locals => { :authenticated => authenticated? }
  else
    check_access_token
    erb :index, :locals => {
      :authenticated => authenticated?, :recent_commits => recent_commits }
  end
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
    result[:and_criteria_met] =
      result[:and_criteria][:commit_in_valid_branch] &&
      result[:and_criteria][:repo_not_a_fork] &&
      result[:and_criteria][:commit_email_linked_to_user]
    result[:or_criteria_met] =
      result[:or_criteria][:user_has_starred_repo] ||
      result[:or_criteria][:user_can_push_to_repo] ||
      result[:or_criteria][:user_is_repo_org_member] ||
      result[:or_criteria][:user_has_fork_of_repo] ||
      result[:or_criteria][:user_has_opened_issue_or_pr_in_repo]
    result[:default_branch_is_gh_pages] =
      result[:and_criteria][:default_branch] == "gh-pages"

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

# Show the 'How does this work?' page.
get "/how" do
  erb :how, :locals => { :authenticated => authenticated? }
end

# Ping endpoing for uptime check.
get "/ping" do
  "pong"
end
