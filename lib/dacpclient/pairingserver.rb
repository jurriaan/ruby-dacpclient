require 'socket'
require 'dnssd'
require 'digest'
require 'gserver'
module DACPClient
  # The pairingserver handles pairing with iTunes
  class PairingServer < GServer
    attr_accessor :pin, :device_type

    MDNS_TYPE = '_touch-remote._tcp'.freeze

    def initialize(name, host, port = 1024)
      @name = name
      @port = port
      @host = host
      @pair = Client.get_guid(@name)
      @pin = [0, 0, 0, 0]
      @device_type = 'iPod'
      super port, host
    end

    def start
      @pairing_string = generate_pairing_string(@pair, @name, @device_type)
      @expected = PairingServer.generate_pin_challenge(@pair, @pin)
      @service = DNSSD.register!(@name, MDNS_TYPE, 'local', @port, text_record)

      super
      join

      @service.stop

      sleep 0.5 # sleep so iTunes accepts our login
    end

    def self.generate_pin_challenge(pair, pin)
      pin_string = pin.map { |i| "#{i}\x00" }.join
      Digest::MD5.hexdigest(pair + pin_string).upcase
    end

    def serve(client)
      code = client.gets.match(/pairingcode=([^&]*)/)[1]
      correct = code == @expected
      if correct
        client.print "HTTP/1.1 200 OK\r\n" +
                     "Content-Length: #{@pairing_string.length}\r\n\r\n"
        client.print @pairing_string
      else
        client.print "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"
      end
      client.close
      stop if correct
    end

    private

    def text_record
      DNSSD::TextRecord.new({
        'DvNm' => @name,
        'Revm' => '10000',
        'DvTy' => @device_type,
        'RemN' => 'Remote',
        'txtvers' => '1',
        'Pair' => @pair
      })
    end

    def generate_pairing_string(pair, name, device_type)
      DMAPBuilder.cmpa do
        cmpg pair
        cmnm name
        cmty device_type
      end.to_dmap
    end
  end
end