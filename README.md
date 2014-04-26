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

    Usage: dacpclient [command]
    (c) 2014 Jurriaan Pruis <email@jurriaanpruis.nl>

    Where command is one of the following:
    status
    status_ticker
    play
    pause
    playpause
    next
    prev
    databases
    playqueue
    upnext
    stop
    debug
    usage
    previous
    help

## Todo

- Use bonjour
- Add tests
- Add more tagdefinitions
- Documentation

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -tb my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

- [Jurriaan Pruis](https://github.com/jurriaan)

## Thanks

- [edc1591](https://github.com/edc1591) - for some of the 'Up Next' code