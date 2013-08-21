module DACPClient
  # The Client class handles communication with the server
  class Bonjour
    SERVICE_NAME = '_daap._tcp'.freeze
    DOMAIN = 'local'.freeze

    def browse
      servers = []

      begin
        timeout(3) do
          DNSSD.browse!(SERVICE_NAME, DOMAIN) do |node|
            ip, port = nil

            resolver = DNSSD::Service.new
            resolver.resolve(node) do |resolved|
              ip = get_ip(resolved.target)
              port = resolved.port

              break unless resolved.flags.more_coming?
            end

            servers << { name: node.name, ip: ip, port: port, node: node }

            break unless node.flags.more_coming?
          end
        end
        
      rescue Timeout::Error
      end

      servers
    end

    private

    def get_ip(target)
      info = Socket.getaddrinfo(target, nil, Socket::AF_INET)
      info[0][2]
    end
  end
end