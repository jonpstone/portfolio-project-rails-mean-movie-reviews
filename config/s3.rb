CarrierWave.configure do |config|
  config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => "AKIAI4S2ZHRPFQNQECIQ",
      :aws_secret_access_key  => "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",
      :region                 => 'us-east-2' # Change this for different AWS region. Default is 'us-east-1'
  }
  config.fog_directory  = "mean-review-assets"
end
