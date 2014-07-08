class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  #protect_from_forgery with: :null_session
  
  def api_connect(path, order_number)
    api_key = ENV['MAKR_API_KEY']
    api_secret = ENV['MAKR_API_SECRET']
    api_url = ENV['MAKR_API_URL']
    api_version = ENV['MAKR_API_VERSION']
    
    if order_number != "none"
      path = File.join(path, order_number)
    end  
    timestamp = Time.now.to_i
  	signature = "version=#{api_version}&path=#{path}&app_key=#{api_key}&app_secret=#{api_secret}&timestamp=#{timestamp}"
  	signature_hash = Digest::SHA2.new << signature
  	url = "#{api_url}#{api_version}#{path}?app_key=#{api_key}&timestamp=#{timestamp}&signature=#{signature_hash}"

    url
  end  
  
  def api_auth(path, auth_hash)
    url = api_connect(path, 'none')
  	begin
  	  response = RestClient.post url, :email => auth_hash[:email], :password => auth_hash[:password]
  	rescue
  	end
    if response.to_s.include?('{"meta":{"status":200,"msg":"OK"}')
       api_auth = JSON.parse(response)
       @user_hash = {
         :email => api_auth["response"]["email"],
         :first_name => api_auth["response"]["first_name"],
         :type => api_auth["response"]["type"],
       }
    end
    @user_hash
  end
  
  def get_order(path, order_number)
    url = api_connect(path, order_number)
  	response = RestClient.get url
  	begin
  	  response = RestClient.get url
  	rescue
  	end
    if response.to_s.include?('{"meta":{"status":200,"msg":"OK"}')
       order_status = JSON.parse(response)
       order_hash = {
         :status => order_status["response"]["order"]["status"],
         :order_created => order_status["response"]["order"]["created_at"]
       }
    end
    order_hash
  end
  
  protected

  class OrdersBucket < AWS::S3::Bucket
    AWS::S3::Base.establish_connection!(
      :access_key_id => ENV['S3_KEY'],
      :secret_access_key => ENV['S3_SECRET'])
    set_current_bucket_to ENV['S3_BUCKET']
  end
  
  class OrdersObject < AWS::S3::S3Object
    AWS::S3::Base.establish_connection!(
      :access_key_id => ENV['S3_KEY'],
      :secret_access_key => ENV['S3_SECRET'])
    set_current_bucket_to ENV['S3_BUCKET']
  end
  
  def confirm_logged_in
    session[:makr] = cookies.signed[:makr] if cookies[:makr]
    #redirect_to orders_url
    unless cookies[:makr]
      redirect_to root_url
      return false
    else
      return true
    end
  end
  
end
