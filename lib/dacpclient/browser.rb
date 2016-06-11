require 'timeout'
require 'ostruct'

module DACPClient
  # The Client class handles communication with the server
  class Browser
    class Service < Struct.new(:name, :host, :port, :text_records)
      def library_name
        text_records['CtlN'] || text_records['Machine Name']
      end

      def database_id
        text_records['DbId'] || text_records['Database ID']
      end
    end

    DAAP_SERVICE = '_daap._tcp'.freeze
    TOUCHABLE_SERVICE = '_touch-able._tcp'.freeze

    attr_reader :services

    def initialize
      @services = []
    end

    def browse
      @services = []
      Timeout.timeout(5) do
        DNSSD.browse!(TOUCHABLE_SERVICE) do |node|
          resolve(node)
          break unless node.flags.more_coming?
        end
      end
      services
    rescue Timeout::Error # => e
      []
    end

    private

    def node_resolver(_node, resolved)
      services << Service.new(resolved.name, get_device_host(resolved),
                              resolved.port, resolved.text_record)

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
