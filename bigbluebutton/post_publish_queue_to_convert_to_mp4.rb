#!/usr/bin/ruby
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation; either version 3.0 of the License, or (at your option)
# any later version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
#

require "trollop"
require "/usr/local/recording-converter-uploader/worker"
require File.expand_path('../../../lib/recordandplayback', __FILE__)

opts = Trollop::options do
  opt :meeting_id, "Meeting id to archive", :type => String
end
meeting_id = opts[:meeting_id]

logger = Logger.new("/var/log/bigbluebutton/post_publish.log", 'weekly' )
logger.level = Logger::INFO
BigBlueButton.logger = logger

published_files = "/var/bigbluebutton/published/presentation/#{meeting_id}"
meeting_metadata = BigBlueButton::Events.get_meeting_metadata("/var/bigbluebutton/recording/raw/#{meeting_id}/events.xml")

# References for finding recording marks and deleting if none found:
# https://docs.bigbluebutton.org/admin/privacy.html
# https://github.com/OskarCarl/bbb-recording-archive-workaround/blob/master/usr/local/bigbluebutton/core/scripts/post_archive/delete_raw_if_no_recording.rb

def meeting_has_recording_marks?(meeting_id)
  config = File.expand_path('../../bigbluebutton.yml', __FILE__)
  BigBlueButton.logger.info("Loading configuration #{config}")
  props = YAML::load(File.open(config))
  recording_dir = props['recording_dir']
  archived_files = "#{recording_dir}/raw/#{meeting_id}"

  events = Nokogiri::XML(File.open("#{archived_files}/events.xml"))
  rec_events = BigBlueButton::Events.get_record_status_events(events)
  if rec_events.length > 0
    true
  else
    false
  end
end

# TODO: what about events in redis?
# TODO: not sure about notes; are they kept in the etherpad?
def delete_audio(meeting_id, audio_dir)
  BigBlueButton.logger.info("Deleting audio #{audio_dir}/#{meeting_id}-*.*")
  audio_files = Dir.glob("#{audio_dir}/#{meeting_id}-*.*")
  if audio_files.empty?
    BigBlueButton.logger.info("No audio found for #{meeting_id}")
    return
  end
  audio_files.each do |audio_file|
    #BigBlueButton.logger.info("sudo rm -f #{audio_file}") # debug output
    system('sudo', 'rm', '-f', "#{audio_file}") || BigBlueButton.logger.warn('Failed to delete audio')
  end
end

def delete_directory(source)
  BigBlueButton.logger.info("Deleting contents of #{source} if present.")
  #BigBlueButton.logger.info("sudo rm -rf #{source}") # debug output
  system('sudo', 'rm', '-rf', "#{source}") || BigBlueButton.logger.warn('Failed to delete directory')
end

##### START ########

if meeting_has_recording_marks?(meeting_id)
  jobid = ConvertToMp4.perform_async(meeting_id, meeting_metadata["uploadrecordingcredentialsurl"])
  BigBlueButton.logger.info("Added job #{jobid} for meeting_id #{meeting_id} to queue for converting to mp4")
else
  BigBlueButton.logger.info("There are no recording marks for #{meeting_id}, deleting the recording.")

  audio_dir = props['raw_audio_src']
  deskshare_dir = props['raw_deskshare_src']
  screenshare_dir = props['raw_screenshare_src']
  presentation_dir = props['raw_presentation_src']
  video_dir = props['raw_video_src']
  kurento_video_dir = props['kurento_video_src']
  kurento_screenshare_dir = props['kurento_screenshare_src']

  # delete the successfully archived files
  #BigBlueButton.logger.info("sudo bbb-record --delete #{meeting_id}") # debug output
  system('sudo', 'bbb-record', '--delete', "#{meeting_id}") || BigBlueButton.logger.warn('Failed to delete local recording')

  # delete the raw captures that might still remain
  delete_audio(meeting_id, audio_dir)
  delete_directory("#{presentation_dir}/#{meeting_id}/#{meeting_id}")
  delete_directory("#{screenshare_dir}/#{meeting_id}")
  delete_directory("#{video_dir}/#{meeting_id}")
  delete_directory("#{kurento_screenshare_dir}/#{meeting_id}")
  delete_directory("#{kurento_video_dir}/#{meeting_id}")
end

exit 0
