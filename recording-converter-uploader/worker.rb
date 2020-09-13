require 'sidekiq'
require 'logger'
require 'net/http'
require 'uri'
require File.expand_path('../VdoCipherRubyUploader/vdo_cipher_uploader',__FILE__)

Sidekiq.configure_client do |config|
  config.redis = { db: 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { db: 1 }
end

LOGGER = Logger.new("/var/log/bigbluebutton/post_publish.log", 'weekly' )
LOGGER.level = Logger::INFO


#meeting_id used here is the internal meeting id created by bigbluebutton 
#which is session_id on teachmore

class ConvertToMp4
  include Sidekiq::Worker
  sidekiq_options :queue => :convert 

  def perform(meeting_id, upload_recording_credentials_url)
    LOGGER.info("Start exporting #{meeting_id} to mp4")

    bbb_recorder_cmd = "node /usr/local/bbb-recorder/export.js 'https://live.teachmore.in/playback/presentation/2.0/playback.html?meetingId=#{meeting_id}' #{meeting_id} 0 true '#{upload_recording_credentials_url}'"
    
    status = system(bbb_recorder_cmd)

    LOGGER.info(status)
    LOGGER.info("End exporting #{meeting_id} to mp4")
  end
end

class UploadToVdocipher
  include Sidekiq::Worker
  sidekiq_options :queue => :upload

  def perform(meeting_id, filepath, credentials_request_url)
    upload_credentials = get_upload_credentials(meeting_id, filepath, credentials_request_url)
    params = upload_credentials["data"]
    uri = URI(upload_credentials["url"])
    request = VdoCipher::Uploader.prepare_request(uri, params, filepath)
    LOGGER.info("Start uploading #{meeting_id} to vdocipher")
    puts "Start uploading #{meeting_id} to vdocipher"
    response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: true }) do |http|
      http.request(request)
    end
    puts "End uploading #{meeting_id} to vdocipher with response #{response.code}: #{response.body}"
    LOGGER.info("End uploading #{meeting_id} to vdocipher with response #{response.code}: #{response.body}")
  end

  def get_upload_credentials(meeting_id, filepath, credentials_request_url)
    uri = URI(credentials_request_url)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri)
    params = {
      uid: meeting_id,
      filename: meeting_id,
      file_type: 'video/mp4',
      file_size: File.size(filepath)
    }.to_json
    req.body = params
    req['Authorization'] = 'Bearer zh0gzfcza2h904j1noqzdurc2qy8ttm3goiwolfm'
    req['Accept'] = 'application/json'
    req['Content-Type'] = 'application/json'
    
    LOGGER.info("Getting upload credentials from #{uri.scheme}://#{uri.host}#{uri.request_uri}")
    upload_credentials_response = http.request(req)
    LOGGER.info("Response to upload credentials for recording of #{meeting_id}: #{upload_credentials_response.body}")
  
    return JSON.parse(upload_credentials_response.body)
  end
end
