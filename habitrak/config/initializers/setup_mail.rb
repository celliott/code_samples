ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
	:port                 => 587,
	:domain               => 'cheapandsalty.com',
	:user_name            => 'habitrak@cheapandsalty.com',
	:password             => 'Fulton19',
	:authentication       => 'plain',
	:enable_starttls_auto => true 
}
ActionMailer::Base.default_url_options[:host] = 'localhost:3000' if Rails.env.development?
ActionMailer::Base.default_url_options[:host] = 'www.habitrakapp.com' if Rails.env.production?