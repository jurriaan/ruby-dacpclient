require 'timeout'
require 'ostruct'

module DACPClient
  # The Client class handles communication with the server
  class Browser
    class Device < Struct.new(:host, :port, :text_records)
      def name
        text_records['Machine Name'] || text_records['CtlN']
      end

      def database_id
        text_records['Database ID'] || text_records['DbId']
      end
    end

    DAAP_SERVICE = '_daap._tcp'.freeze
    TOUCHABLE_SERVICE = '_touch-able._tcp'.freeze

    attr_reader :devices

    def initialize
      @devices = []
    end

    def browse
      @devices = []
      timeout(5) do
        DNSSD.browse!(TOUCHABLE_SERVICE) do |node|
          resolve(node)
          break unless node.flags.more_coming?
        end
      end
      devices
    rescue Timeout::Error # => e
      []
    end

    private

    def node_resolver(_node, resolved)
      devices << Device.new(get_device_host(resolved), resolved.port,
                            resolved.text_record)

      resolved.flags.more_coming?
    end

    def get_device_host(resolved)
      target = resolved.target
      info = Socket.getaddrinfo(target, nil, Socket::AF_INET)
      info[0][2]
    rescue SocketError
      target
    end

    def resolve(node)
      resolver = DNSSD::Service.new
      resolver.resolve(node) do |resolved|
        break unless node_resolver(node, resolved)
      end
    end
  end
end
