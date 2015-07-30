#!/usr/bin/env ruby
# coding: utf-8

require 'rubygems'
require 'net/http'
require 'yaml'

# Get track info from STDIN
event = ARGV[0]
track = {}
STDIN.each_line do |l|
  track.store(*l.chomp.split('=', 2))
end

# write the STDIN to a log file so we can debug
dbg = {"#{ARGV[0]}"=>track,:time=>Time.now.localtime}
logfile_path = File.join(File.expand_path(File.dirname(__FILE__)), 'stdin.txt')
f = File.open(logfile_path,"w")
f.write "#{dbg.to_yaml}\n"
f.close

module LFm
  require 'yaml'
  require 'lastfm'

  def scrobble(track)
    begin
      return true
    ensure
      # Scrobble songs on finish, if we listened to at least 75% of the track
      if (track['songDuration'].to_i*0.75).to_i <= track['songPlayed'].to_i
        fm.track.scrobble(
          :artist => track['artist'],
          :track => track['title'],
          :album=>track['album'],
          :chosenByUser => 0
        )
      end
    end
  end

  def love(track)
    begin
      return true
    ensure
      # Love songs on thumbs up.
      fm.track.love(
        :artist=>track['artist'],
        :track=>track['title']
      )
    end
  end

  def ban(track)
    begin
      return true
    ensure
      # ban songs on thumbs down
      fm.track.ban(
        :artist=>track['artist'],
        :track=>track['title']
      )
    end
  end

  def update_now_playing(track)
    begin
      return true
    ensure
      # Update the now playing in LastFM.
      fm.track.update_now_playing(
        :artist=>track['artist'],
        :track=>track['title'],
        :album=>track['album']
      )

      if track['rating'] and track['rating'].to_i==1
        # Playing a song that was previously set to thumbs up on Pandora
        fm.track.love(
          :artist=>track['artist'],
          :track=>track['title']
        )
      end
    end
  end

  private

  def fm
    # create Lastfm instance
    fm = Lastfm.new(settings["api_key"], settings["api_secret"])
    fm.session = settings["session_key"]
    fm
  end

  # Last.fm API connection settings. You need to:
  #   1. Create an API application
  #   2. Generate a token and auth URL
  #   3. Visit the auth URL and authorize the app
  #   4. Generate a session_key
  def settings
    YAML.load(File.open(File.join(File.expand_path(File.dirname(__FILE__)), 'last_fm.yml')).read)
  end

end

# a module to test for a installed binary
module BinaryCheck
  def self.installed?(filename)
    paths_for_filename(filename).each do |p|
      return true if File.executable?(File.join(p, filename.to_s))
    end
    false
  end
  private
  def self.paths_for_filename(filename)
    ENV["PATH"].split(File::PATH_SEPARATOR).map{|p| p if File.exists?(File.join(p, filename.to_s)) }.compact
  end
end

# a module for desktop notifications
module DesktopNotification
  include BinaryCheck
  def self.notify(params={})
    ## Desktop Notification
    # Check to see if we have the ability to do a desktop notification and create
    # a platform-specific string to execute in a shell
    notifyable = false # initialize as false

    # Need to define the local filename for coverart before we set `exec_string` variable
    coverart_filename = File.join(File.expand_path(File.dirname(__FILE__)), 'coverart')

    # Thumbs Up/Down char
    rating = nil
    if params['rating']
      case params['rating'].to_i
        when 1:
          rating = "\342\207\247 "
        when 2:
          rating = "\342\207\251 "
      end
    end

    if /cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM
      # Windows platform
      # If we have a way to do desktop notifications in Windows, this is the place to do
    else
      if /darwin/ =~ RUBY_PLATFORM
        # Mac / OSX platform
        if BinaryCheck.installed?('terminal-notifier')
          notifyable = true
          exec_string = "terminal-notifier -title \"#{rating}#{params['artist'].gsub('"','\"')} - #{params['title'].gsub('"','\"')}\" -message \"#{params['album'].gsub('"','\"')} (#{params['stationName'].gsub('"','\"')})\" -group \"Pianobar\" -open \"#{params['detailUrl']}\""

          # make the notification use iTunes icon instead of default Terminal icon
          # (we cannot use album art in notification unless we are in OSX 10.9.x or higher)
          exec_string += " -sender \"com.apple.iTunes\""
          exec_string += " -contentImage \"#{coverart_filename}\""
        elsif BinaryCheck.installed?('growlnotify')
          notifyable = true
          exec_string = "growlnotify --title \"#{rating}#{params['artist'].gsub('"','\"')} - #{params['title'].gsub('"','\"')}\" --message \"#{params['album'].gsub('"','\"')} (#{params['stationName'].gsub('"','\"')})\" --name \"Pianobar\" --image \"#{coverart_filename}\""
        end
      else
        # Linux / Unix platform
        if BinaryCheck.installed?('notify-send')
          notifyable = true
          exec_string = "notify-send --urgency=low --app-name=Pianobar --expire-time=5000 --icon=#{coverart_filename} --hint=int:transient:1 --category=transfer \"#{rating}#{params['artist'].gsub('"','\"')} - #{params['title'].gsub('"','\"')}\" \"#{params['album'].gsub('"','\"')} (#{params['stationName'].gsub('"','\"')})\""
        end
      end
    end

    if notifyable
      # download cover art to local file b/c notifications won't show image if it is a URI
      coverart_uri = URI(params['coverArt'])
      Net::HTTP.start(coverart_uri.host,coverart_uri.port) do |http|
        response = http.get(coverart_uri.path)
        f = File.open(coverart_filename,"wb")
        f.write response.body
        f.close
      end

      # execute a shell to create notification
      `#{exec_string}`

      # wait one second and then delete local coverart file
      Kernel.sleep 1
      File.unlink(coverart_filename)
    end
  end
end

include DesktopNotification
include LFm

# Handle events.
case event
  when 'songfinish'
    LFm.scrobble track
  when 'songlove'
    DesktopNotification.notify track
    LFm.love track
  when 'songstart'
    DesktopNotification.notify track
    LFm.update_now_playing track
  when 'songban'
    DesktopNotification.notify track
    LFm.ban track
  when 'songshelf'
    # "I'm tired of this song" (1 month ban on Pandora)
  when 'songexplain'
    # Pandora's reason for playing this track
    DesktopNotification.notify track
end
