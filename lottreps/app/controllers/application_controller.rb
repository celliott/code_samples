#require 'debugger'; debugger

class ApplicationController < ActionController::Base
  protect_from_forgery

  class ArtworksBucket < AWS::S3::Bucket
    AWS::S3::Base.establish_connection!(
      :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key =>  ENV["AWS_SECRET_KEY"])
    set_current_bucket_to ENV["AWS_S3_BUCKET"]
  end
  
  class ArtworksObject < AWS::S3::S3Object
    AWS::S3::Base.establish_connection!(
      :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key =>  ENV["AWS_SECRET_KEY"])
    set_current_bucket_to ENV["AWS_S3_BUCKET"]
  end 
  
end
