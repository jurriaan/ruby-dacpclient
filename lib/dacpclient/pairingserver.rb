require 'socket'
require 'dnssd'
require 'digest'
module DACPClient
  class PairingServer
    attr_accessor :pin, :device_type
    def initialize(name, host, port = 1024)
      @name = name
      @port = port
      @host = host
      @pair = Client.get_guid(@name)
      @pin = [0, 0, 0, 0]
      @device_type = 'iPod'
    end

    def start
      device_type = @device_type
      puts "Pairing started (pincode=#{@pin.join})"

      pairing_string = generate_pairing_string @pair, @name, @device_type

      expected = PairingServer.generate_pin_challenge(@pair, @pin)
      server = TCPServer.open(@host, @port)
      @service = DNSSD.register!(@name, '_touch-remote._tcp', 'local', @port, text_record)

      while (client = server.accept)
        get = client.gets
        code = get.match(/pairingcode=([^&]*)/)[1]

        if code == expected
          client.print "HTTP/1.1 200 OK\r\nContent-Length: #{pairing_string.length}\r\n\r\n#{pairing_string}"
          puts 'Pairing succeeded :)'
          client.close
          @service.stop
          break
        else
          puts 'Wrong pincode entered'
          client.print "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"
        end
        client.close
      end
      server.close

      sleep 1 # sleep so iTunes accepts our login
    end

    def self.generate_pin_challenge(pair, pin)
      pin_string = pin.map { |i| "#{i}\x00" }.join
      Digest::MD5.hexdigest(pair + pin_string).upcase
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

    def generate_pairing_string pair, name, device_type
      DMAPBuilder.cmpa do
        cmpg pair
        cmnm name
        cmty device_type
      end.to_dmap
    end
  end
end