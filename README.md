pianobar
========

## Overview

This is a Pianobar event_command script with Last.fm scrobbling, and desktop notifications for Linux and OSX.

## Prerequisites:
* Ruby
* You need to install Pianobar first: https://github.com/PromyLOPh/pianobar
  * setup your config file, located `PATH_TO_HOME_FOLDER/.config/pianobar/config`:

      ```
      # User
      user = YOUR_EMAIL_ADDRESS_FOR_PANDORA_ACCOUNT
      password = YOUR_PASSWORD_FOR_PANDORA_ACCOUNT

      # Misc
      event_command = PATH_TO_HOME_FOLDER/.config/pianobar/pianobar-lastfm.rb

      # high-quality audio (192k mp3, for Pandora One subscribers only!)
      audio_quality = high
      rpc_host = tuner.pandora.com
      tls_fingerprint = 2D0AFDAFA16F4B5C0A43F3CB1D4752F9535507C0
      ```
* for desktop notifications:
  * OSX: install the free version of Growl: http://growl.info/downloads
     * (growl has to be running to see notifications)
  * Linux: you need `notify-send` which is usually installed with `libnotify`
* for Last.fm scrobbling:
  * install the `lastfm` rubygem
  * You need to create an API account/app for Pianobar and create an authorized session token
  * create a config file with your Last.fm credentials.  Place the file in the `~/.config/pianobar` folder and name it `last_fm.yml`:

      ```yaml
      --- 
      api_secret: YOUR_API_SECRET
      session_key: YOUR_SESSION_KEY
      api_key: YOUR_API_KEY
      ```
