class ContactForm < MailForm::Base
  attribute :name, :presence => true
  attribute :sender_email, :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :message, :presence => true
  
  
  def headers
    {
      :subject => "Lott Reps Contact Form",
      :to => "peter@lottreps.com",
      :from => "info.lottreps@gmail.com"
    }
  end
end