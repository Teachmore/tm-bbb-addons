# This script requires certain root privileges to delete the raw files.
# It uses sudo as a workaround to be able to delete the files owned by the various other applications.

require "trollop"
require "net/http"
require "uri"
require "/usr/local/bigbluebutton/core/lib/recordandplayback"

# TODO: what about events in redis?
# TODO: not sure about notes; are they kept in the etherpad?

def has_recording_marks_callback(meeting_id, has_recording_marks, request_url)
  uri = URI(request_url)
  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri)
  params = {
    uid: meeting_id,
    has_recording_marks: has_recording_marks
  }.to_json
  req.body = params
  req['Authorization'] = 'Bearer zh0gzfcza2h904j1noqzdurc2qy8ttm3goiwolfm'
  req['Accept'] = 'application/json'
  req['Content-Type'] = 'application/json'
  BigBlueButton.logger.info("Update teachmore #{meeting_id} has_recording_marks: #{has_recording_marks}")
  response = http.request(req)
  BigBlueButton.logger.info("Response from teachmore: #{response.body}")
end

####################### START #################################################

opts = Trollop::options do
  opt :meeting_id, "Meeting id to archive", :type => String
end
Trollop::die :meeting_id, "must be provided" if opts[:meeting_id].nil?
meeting_id = opts[:meeting_id]
meeting_metadata = BigBlueButton::Events.get_meeting_metadata("/var/bigbluebutton/recording/raw/#{meeting_id}/events.xml")


# requires permissions to write to this path as current user
logger = Logger.new("/var/log/bigbluebutton/post_archive.log", 'weekly' )
logger.level = Logger::INFO
BigBlueButton.logger = logger
BigBlueButton.logger.info("Checking if raw recordings for #{meeting_id} should be deleted.")

config = File.expand_path('../../bigbluebutton.yml', __FILE__)
BigBlueButton.logger.info("Loading configuration #{config}")
props = YAML::load(File.open(config))
recording_dir = props['recording_dir']
archived_files = "#{recording_dir}/raw/#{meeting_id}"

events = Nokogiri::XML(File.open("#{archived_files}/events.xml"))
rec_events = BigBlueButton::Events.get_record_status_events(events)
if not rec_events.length > 0
  BigBlueButton.logger.info("There are no recording marks for #{meeting_id}, deleting the recording.")
  has_recording_marks_callback(meeting_id, false, meeting_metadata["hasrecordingcallbackurl"])
  # delete the successfully archived files
  #BigBlueButton.logger.info("sudo bbb-record --delete #{meeting_id}") # debug output
  system('sudo', 'bbb-record', '--delete', "#{meeting_id}") || BigBlueButton.logger.warn('Failed to delete local recording')

else
  has_recording_marks_callback(meeting_id, true, meeting_metadata["hasrecordingcallbackurl"])
  BigBlueButton.logger.info("Found recording marks for #{meeting_id}, keeping the recording.")
end

exit 0

