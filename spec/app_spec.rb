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
        expect(last_response.headers["Location"]).to \
          eq("https://github.com/login/oauth/authorize?scope=user:email&client_id=myclientid")
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
