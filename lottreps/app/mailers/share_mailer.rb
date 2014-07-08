class ShareMailer < ActionMailer::Base
  default from: "info.lottreps@gmail.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.share_mailer.send_to_friend.subject
  #
  def send_to_friend(email)
    @greeting = "Hi"

    mail to: email
  end
end
