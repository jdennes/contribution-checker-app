require "helper"

set :environment, :test

describe "The Contribution Checker app" do

  let(:app) { Sinatra::Application }

  describe "/" do

    context "when app is not authorised" do

      it "redirects to request authorisation" do
        get "/"
        expect(last_response.status).to eq(302)
        expect(last_response.headers['Location']).to \
          eq("https://github.com/login/oauth/authorize?scope=user:email&client_id=myclientid")
      end

    end

  end

end
