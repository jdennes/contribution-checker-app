require "helper"

set :environment, :test

describe "The Contribution Checker app" do

  let(:app) { Sinatra::Application }
  let(:client_id) { ENV["GITHUB_CLIENT_ID"] }
  let(:client_secret) { ENV["GITHUB_CLIENT_SECRET"] }

  describe "GET /" do

    context "when the app is not authorised" do
      it "redirects to request authorisation" do
        get "/"

        expect(last_response.status).to eq(302)
        expect(last_response.location).to \
          eq("https://github.com/login/oauth/authorize?scope=user:email&client_id=myclientid")
      end
    end

    context "when the app is authorised but the token is invalid" do
      before do
        stub_request(:get, "https://api.github.com/user").
          to_return(:status => 401)
      end

      it "checks token and redirects to request authorisation" do
        get "/", {}, { "rack.session" => { :access_token => "x" * 40 } }

        expect(last_request.env["rack.session"][:access_token]).to eq(nil)
        expect(last_response.status).to eq(302)
        expect(last_response.location).to \
          eq("https://github.com/login/oauth/authorize?scope=user:email&client_id=myclientid")
      end
    end

    context "when the app is authorised and the token is valid" do
      let(:access_token) { "myaccesstoken" }

      before do
        stub_request(:get, "https://api.github.com/user").
          to_return(json_response("user.json"))
        stub_request(:get, "https://api.github.com/users/jdennes/events/public").
          to_return(json_response("public_events.json"))
      end

      it "checks token and redirects to request authorisation" do
        get "/", {}, { "rack.session" => { :access_token => access_token } }

        expect(last_request.env["rack.session"][:access_token]).to eq(access_token)
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("recent public commits")
      end
    end

  end

  describe "POST /" do

    context "when an invalid commit url is provided" do
      let(:access_token) { "myaccesstoken" }

      before do
        expect_any_instance_of(ContributionChecker::Checker).to receive(:check).
          and_raise(ContributionChecker::InvalidCommitUrlError)

        stub_request(:get, "https://api.github.com/user").
          to_return(json_response("user.json"))
        stub_request(:get, "https://api.github.com/users/jdennes/events/public").
          to_return(json_response("public_events.json"))
      end

      it "returns a json response containing an error message" do
        post "/", { :url => "not a url" }, { "rack.session" => { :access_token => access_token } }

        expect(last_request.env["rack.session"][:access_token]).to eq(access_token)
        expect(last_response.status).to eq(200)
        expect(last_response.headers["Content-Type"]).to eq("application/json")
        expect(last_response.body).to include("error_message")
      end
    end

  end

  describe "GET /callback" do

    let(:code) { "mytempcode" }
    let(:access_token) { "myaccesstoken" }

    before do
       stub_request(:post, "https://github.com/login/oauth/access_token").
         with(:body => "{\"code\":\"#{code}\",\"client_id\":\"#{client_id}\",\"client_secret\":\"#{client_secret}\"}",
              :headers => { "Accept" => "application/json", "Content-Type" => "application/json" }).
         to_return(json_response("access_token.json"))
    end

    it "exchanges the temporary code from GitHub for an access token" do
      get "/callback?code=#{code}"

      expect(last_request.env["rack.session"][:access_token]).to eq(access_token)
      expect(last_response.status).to eq(302)
    end

  end

end
