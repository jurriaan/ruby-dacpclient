require 'socket'
require 'dnssd'
require 'digest'
require 'gserver'
require 'dmapparser/builder'
module DACPClient
  # The pairingserver handles pairing with iTunes
  class PairingServer < GServer
    attr_accessor :pin, :device_type
    attr_reader :peer

    MDNS_TYPE = '_touch-remote._tcp'.freeze

    def initialize(name, guid, host = '0.0.0.0', port = 1024)
      @name = name
      @port = port
      @host = host
      @pair = guid
      @pin = [0, 0, 0, 0]
      @peer = nil
      @device_type = 'iPod'
      super port, host
    end

    def start
      @pairing_string = generate_pairing_string(@pair, @name, @device_type)
      @expected = PairingServer.generate_pin_challenge(@pair, @pin)
      @service = DNSSD.register!(@name, MDNS_TYPE, 'local', @port, text_record)
      @pairing_string
      PairInfo.new(DMAPParser::Parser.parse(@pairing_string))
      super
      join

      @service.stop

      sleep 0.5 # sleep so iTunes accepts our login
      peer
    end

    def self.generate_pin_challenge(pair, pin)
      pin_string = pin.map { |i| "#{i}\x00" }.join
      Digest::MD5.hexdigest(pair.upcase + pin_string).upcase
    end

    def serve(client)
      data = client.gets
      peer_addr = client.peeraddr[2]
      browser = DACPClient::Browser.new
      browser.browse
      @peer = browser.devices.find do |device|
        device.host == peer_addr
      end
      if data =~ /pairingcode=#{@expected}/i && @peer
        client.print "HTTP/1.1 200 OK\n" +
                     "Content-Length: #{@pairing_string.length}\n\n"
        client.print @pairing_string
        client.close
        stop
      else
        client.print "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"
        client.close
      end
    end

    private

    def text_record
      DNSSD::TextRecord.new(
        'DvNm' => @name,
        'Revm' => '10000',
        'DvTy' => @device_type,
        'RemN' => 'Remote',
        'txtvers' => '1',
        'Pair' => @pair.upcase
      )
    end

    def generate_pairing_string(pair, name, device_type)
      PairInfo.build_dmap(pairing_code: pair, name: name, type: device_type)
    end
  end
end
