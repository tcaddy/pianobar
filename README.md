pianobar
========

## Overview

This is a Pianobar event_command script with Last.fm scrobbling, and desktop notifications for Linux and OSX.

## Prerequisites:
* Ruby
* You need to install Pianobar first: https://github.com/PromyLOPh/pianobar
  * set the config file to use a custom `event_command`:
    `event_command = PATH_TO_HOME_FOLDER/.config/pianobar/pianobar-lastfm.rb`
* for desktop notifications:
  * OSX: install the free version of Growl: http://growl.info/downloads
     * (growl has to be running to see notifications)
  * Linux: you need `notify-send` which is usually installed with `libnotify`
* for Last.fm scrobbling:
  * instal the `lastfm` rubygem
  * You need to create an API account/app for Pianobar and create an authorized session token
  * create a config file with your Last.fm credentials.  Place the file in the `~/.config/pianobar` folder and name it `last_fm.yml`:
    --- 
    api_secret: YOUR_API_SECRET
    session_key: YOUR_SESSION_KEY
    api_key: YOUR_API_KEY

