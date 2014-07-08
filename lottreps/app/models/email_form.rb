class EmailForm < MailForm::Base
  attribute :artist_name, :presence => true
  attribute :email, :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :artist_url, :presence => true
  attribute :sender_name, :presence => true 
  
  
  def headers
    {
      :subject => "Visit #{artist_name} @ Lott Reps",
      :to => "#{email}",
      :from => "info.lottreps@gmail.com"
    }
  end
end