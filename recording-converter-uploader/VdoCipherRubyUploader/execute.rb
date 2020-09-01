require 'bundler/inline'
require 'net/http'
require 'uri'
require './vdo_cipher_uploader.rb'

gemfile do
  source 'https://rubygems.org'
  gem 'mime-types', '~> 3.3', '>= 3.3.1'
end

filename = "sample.mp4"

# Response from PUT /videos (https://dev.vdocipher.com/api/docs/swagger/)
params = {
  "clientPayload": {
    "policy": "",
    "key": "",
    "x-amz-signature": "",
    "x-amz-algorithm": "AWS4-HMAC-SHA256",
    "x-amz-date": "20200828T000000Z",
    "x-amz-credential": "",
    "uploadLink": "https://vdo-ap-southeast.s3-accelerate.amazonaws.com"
  },
  "videoId": ""
}

uri = URI.parse(params[:"clientPayload"][:"uploadLink"])
request = VdoCipher::Uploader.prepare_request(uri, params, filename)
response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: true }) do |http|
  http.request(request)
end

puts response.code
puts response.body