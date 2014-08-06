#DACPClient

[![Gem Version](https://badge.fury.io/rb/dacpclient.png)](http://badge.fury.io/rb/dacpclient) [![Dependency Status](https://gemnasium.com/jurriaan/ruby-dacpclient.png)](https://gemnasium.com/jurriaan/ruby-dacpclient)

A DACP (iTunes Remote protocol) client written in the wonderful Ruby language.
You can use this for controlling iTunes. It uses the same protocol as the iTunes remote iOS app.

You can control iTunes by connecting and entering a pin. 

Look at the [bin/dacpclient](https://github.com/jurriaan/ruby-dacpclient/blob/master/bin/dacpclient) file for an example client.

## Installation

On Linux you need the avahi-dnssd-compat package (`libavahi-compat-libdnssd-dev` on Debian/Ubuntu).

Add this line to your application's Gemfile:

    gem 'dacpclient'

And then execute:

    bundle

Or install it yourself using:

    gem install dacpclient

## Usage

See [bin/dacpclient](https://github.com/jurriaan/ruby-dacpclient/blob/master/bin/dacpclient)

    DACPClient v0.3.1
    (c) 2014 Jurriaan Pruis <email@jurriaanpruis.nl>

    DACPClient commands:
      dacpclient help            # Display all possible commands
      dacpclient help [COMMAND]  # Describe available commands or one specific command
      dacpclient hostname        # Set the hostname
      dacpclient next            # Go to next item
      dacpclient pause           # Pause playing
      dacpclient play            # Start playing
      dacpclient play_playlist   # Plays a playlist
      dacpclient playlists       # Show the playlists
      dacpclient playpause       # Toggle playing
      dacpclient prev            # Go to previous item
      dacpclient status          # Shows the status of the DACP server
      dacpclient stop            # Stop playing
      dacpclient upnext          # Show what's up next
      dacpclient version         # Show DACPClient Version
      dacpclient volume          # Get or set volume

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -tb my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

- [Daisuke Shimamoto](https://github.com/diskshima)
- [Jurriaan Pruis](https://github.com/jurriaan)

## Thanks

- [edc1591](https://github.com/edc1591) - for some of the 'Up Next' code