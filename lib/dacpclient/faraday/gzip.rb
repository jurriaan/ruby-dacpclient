# Copied from github.com/lostisland/faraday_middleware
require 'zlib'
module FaradayMiddleware
  # A middleware that ensures that the client requests are sent with the
  # headers that encourage servers to send compressed data, and then
  # uncompresses it.
  # The Content-Length will reflect the actual body length.
  class Gzip < Faraday::Middleware
    ACCEPT_ENCODING = 'Accept-Encoding'.freeze
    ENCODINGS = 'gzip,deflate'.freeze

    def initialize(app)
      @app = app
    end

    def call(curenv)
      (curenv[:request_headers] ||= {})[ACCEPT_ENCODING] = ENCODINGS
      @app.call(curenv).on_complete do |env|
        encoding = env[:response_headers]['content-encoding'].to_s.downcase
        if %w(gzip deflate).include?(encoding)
          case encoding
          when 'gzip'
            env[:body] = uncompress_gzip(env[:body])
          when 'deflate'
            env[:body] = Zlib::Inflate.inflate(env[:body])
          end
          env[:response_headers].delete('content-encoding')
          env[:response_headers]['content-length'] = env[:body].length
        end
      end
    end

    private

    def uncompress_gzip(body)
      io = StringIO.new(body)
      gzip_reader = if '1.9'.respond_to?(:force_encoding)
                      Zlib::GzipReader.new(io, encoding: 'ASCII-8BIT')
                    else
                      Zlib::GzipReader.new(io)
                    end
      gzip_reader.read
    end
  end
end
