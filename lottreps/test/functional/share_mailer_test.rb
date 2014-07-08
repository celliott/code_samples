require 'test_helper'

class ShareMailerTest < ActionMailer::TestCase
  test "send_to_friend" do
    mail = ShareMailer.send_to_friend
    assert_equal "Send to friend", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
