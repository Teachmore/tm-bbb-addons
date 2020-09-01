require_relative 'worker'


meeting_id = ARGV[0]
filepath = ARGV[1]
credentials_request_url = ARGV[2]

puts "Adding #{meeting_id} at #{filepath} to upload queue #{credentials_request_url}"

UploadToVdocipher.perform_async(meeting_id, filepath, credentials_request_url)
