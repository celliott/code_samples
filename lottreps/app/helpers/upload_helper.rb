# borrowed code from Ryan Bates' railscast #383

module UploadHelper
  def s3_uploader_form(options = {}, &block)
    @artist = Artist.find(params[:artist_id]) if params[:artist_id]
    uploader = S3Uploader.new(@artist.slug, options)
    form_tag(uploader.url, uploader.form_options) do
      uploader.fields.map do |name, value|
        hidden_field_tag(name, value)
      end.join.html_safe + capture(&block)
    end
  end

  class S3Uploader
    def initialize(artist_slug, options)
      @options = options.reverse_merge(
        artist_slug: artist_slug,
        id: "fileupload",
        aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key: ENV["AWS_SECRET_KEY"],
        bucket: ENV["AWS_S3_BUCKET"],
        acl: "public-read",
        expiration: 10.hours.from_now,
        max_file_size: 25.megabytes,
        as: "file",
      )
    end

    def form_options
      {
        id: @options[:id],
        method: "post",
        authenticity_token: false,
        multipart: true,
        data: {
          post: @options[:post],
          as: @options[:as]
        }
      }
    end

    def fields
      {
        :key => key,
        :acl => @options[:acl],
        :policy => policy,
        :signature => signature,
        "AWSAccessKeyId" => @options[:aws_access_key_id],
      }
    end

    def key
      #@key ||= "#{SecureRandom.hex}/${filename}"
      @key ||= "#{@options[:artist_slug]}/${filename}"
    end

    def url
      "https://#{@options[:bucket]}.s3.amazonaws.com/"
    end

    def policy
      Base64.encode64(policy_data.to_json).gsub("\n", "")
    end

    def policy_data
      {
        expiration: @options[:expiration],
        conditions: [
          ["starts-with", "$utf8", ""],
          ["starts-with", "$key", ""],
          ["content-length-range", 0, @options[:max_file_size]],
          {bucket: @options[:bucket]},
          {acl: @options[:acl]}
        ]
      }
    end

    def signature
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          @options[:aws_secret_access_key], policy
        )
      ).gsub("\n", "")
    end
  end
end