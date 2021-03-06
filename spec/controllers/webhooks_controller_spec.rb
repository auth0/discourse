require "rails_helper"

describe WebhooksController do

  context "mailgun" do


    it "works" do
      SiteSetting.mailgun_api_key = "pubkey-8221462f0c915af3f6f2e2df7aa5a493"
      token = "705a8ccd2ce932be8e98c221fe701c1b4a0afcb8bbd57726de"

      user = Fabricate(:user, email: "em@il.com")
      email_log = Fabricate(:email_log, user: user, bounce_key: SecureRandom.hex)
      return_path = "foo+verp-#{email_log.bounce_key}@bar.com"

      $redis.del("mailgun_token_#{token}")
      $redis.del("bounce_score:#{user.email}:#{Date.today}")
      WebhooksController.any_instance.expects(:mailgun_verify).returns(true)

      post :mailgun, "token" => token,
                     "timestamp" => Time.now.to_i,
                     "event" => "dropped",
                     "message-headers" => [["Return-Path", return_path]]

      expect(response).to be_success

      email_log.reload
      expect(email_log.bounced).to eq(true)
      expect(email_log.user.user_stat.bounce_score).to eq(2)
    end

  end

end
