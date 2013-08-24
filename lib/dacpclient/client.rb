require 'rubygems'
require 'bundler'
Bundler.setup(:default)
require 'faraday'
require 'digest'
require 'net/http'
require 'dacpclient/pairingserver'
require 'dacpclient/dmapparser'
require 'dacpclient/dmapbuilder'
require 'dacpclient/bonjour'
require 'uri'
require 'cgi'
require 'plist'

module DACPClient
  # The Client class handles communication with the server
  class Client

    attr_accessor :guid, :hsgid

    attr_reader :name, :host, :port, :session_id

    HOME_SHARING_HOST = 'https://homesharing.itunes.apple.com'
    HOME_SHARING_PATH = '/WebObjects/MZHomeSharing.woa/wa/getShareIdentifiers'

    DEFAULT_HEADERS = {
      'Viewer-Only-Client' => '1',
      # 'Accept-Encoding' => 'gzip',
      'Connection' => 'keep-alive',
      'User-Agent' => 'Remote/2.0'
    }.freeze

    def initialize(name, host = 'localhost', port = 3689)
      @client = Net::HTTP.new(host, port)
      @name = name
      @host = host
      @port = port

      @session_id = nil
      @hsgid = nil
      @mediarevision = 1
      @uri = URI::HTTP.build(host: @host, port: @port)
      @client = Faraday.new(url: @uri.to_s)
    end

    def setup_home_sharing(user, password)
      hs_client = Faraday.new(url: HOME_SHARING_HOST)
      result = hs_client.post do |request|
        request.url HOME_SHARING_PATH
        request.headers['Content-Type'] = 'text/xml'
        request.headers.merge!(DEFAULT_HEADERS)
        request.body = { 'appleId' => user, 'guid' => 'empty',
                         'password' => password }.to_plist
      end
      response = Plist.parse_xml(result.body)
      @hsgid = response['sgid']
    end

    def pair(pin)
      pairingserver = PairingServer.new(@name, '0.0.0.0', 1024)
      pairingserver.pin = pin
      pairingserver.start
    end

    def self.get_guid(name)
      return @guid unless @guid.nil?
      d = Digest::SHA2.hexdigest(name)
      d[0..15]
    end

    def serverinfo
      do_action('server-info', {}, true)
    end

    def login
      response = nil
      if @hsgid.nil?
        pairing_guid = '0x' + Client.get_guid(@name)
        response = do_action(:login, { 'pairing-guid' => pairing_guid })
      else
        response = do_action(:login, { 'hasFP' => '1' })
      end
      @session_id = response[:mlid]
      response
    end

    def pair_and_login(pin = nil)
      login
    rescue DACPForbiddenError => e
      pin = 4.times.map { Random.rand(10) } if pin.nil?
      warn "#{e.result.status} error: Cannot login, starting pairing process"
      warn "Pincode: #{pin}"
      pair(pin)
      retry
    end

    def content_codes
      do_action('content-codes', {}, true)
    end

    def play
      do_action(:play)
    end

    def playpause
      do_action(:playpause)
    end

    def stop
      do_action(:stop)
    end

    def pause
      do_action(:pause)
    end

    def track_length
      response = do_action(:getproperty, properties: 'dacp.playingtime')
      response['cast']
    end

    def seek(ms)
      do_action(:setproperty, 'dacp.playingtime' => ms)
    end

    def get_position
      response = do_action(:getproperty, properties: 'dacp.playingtime')
      response['cast'] - response['cant']
    end

    alias_method :position, :get_position
    alias_method :position=, :seek

    def status(wait = false)
      revision = wait ? @mediarevision : 1
      result = do_action(:playstatusupdate, 'revision-number' => revision)
      @mediarevision = result[:cmsr]
      result
    rescue Faraday::Error::TimeoutError => e
      if wait
        retry
      else
        raise e
      end
    end

    def next
      do_action(:nextitem)
    end

    def prev
      do_action(:previtem)
    end

    alias_method :previous, :prev

    def get_volume
      response = do_action(:getproperty, properties: 'dmcp.volume')
      response[:cmvo]
    end

    def set_volume(volume)
      do_action(:setproperty, 'dmcp.volume' => volume)
    end

    alias_method :volume, :get_volume
    alias_method :volume=, :set_volume

    def get_repeat
      response = do_action(:getproperty, properties: 'dacp.repeatstate')
      response[:carp]
    end

    def set_repeat(volume)
      do_action(:setproperty, 'dmcp.volume' => volume)
    end

    def get_shuffle
      response = do_action(:getproperty, properties: 'dmcp.shufflestate')
      response[:cash]
    end

    def set_shuffle(volume)
      do_action(:setproperty, 'dmcp.volume' => volume)
    end

    def ctrl_int
      do_action('ctrl-int', {}, true)
    end

    def logout
      do_action(:logout)
      @mediarevision = 1
      @session_id = nil
    end

    def queue(id)
      do_action('playqueue-edit', { command: 'add',
                                    query: "\'dmap.itemid:#{id}\'" })
    end

    def clear_queue
      do_action('playqueue-edit', { command: 'clear' })
    end

    def list_queue
      do_action('playqueue-contents')
    end

    def databases
      do_action('databases', {}, true)
    end

    def playlists(db)
      do_action("databases/#{db}/containers", {}, true)
    end

    def default_db
      databases[:mlcl].to_a.find { |item| item.mdbk == 1 }
    end

    def default_playlist(db)
      @client.playlists(72).mlcl.to_a.find { |item| item.abpl }
    end

    def artwork(database, id, width = 320, height = 320)
      url = "databases/#{database}/items/#{id}/extra_data/artwork"
      do_action(url, { mw: width, mh: height }, true)
    end

    def now_playing_artwork(width = 320, height = 320)
      do_action(:nowplayingartwork, { mw: width, mh: height })
    end

    def search(db, container, search, type = nil)
      search = URI.escape(search)
      types = {
        title: 'dmap.itemname',
        artist: 'daap.songartist',
        album: 'daap.songalbum',
        genre: 'daap.songgenre',
        composer: 'daap.songcomposer'
      }
      queries = []
      type = types.keys if type.nil?
      Array(type).each do |t|
        queries << "'#{types[t]}:#{search}'"
      end

      q = queries.join(',')
      meta  = %w(dmap.itemname dmap.itemid daap.songartist daap.songalbumartist
                 daap.songalbum com.apple.itunes.cloud-id dmap.containeritemid
                 com.apple.itunes.has-video com.apple.itunes.itms-songid
                 com.apple.itunes.extended-media-kind dmap.downloadstatus
                 daap.songdisabled).join(',')

      url = "databases/#{db}/containers/#{container}/items"
      do_action(url, { type: 'music', sort: 'album', query: q, meta: meta },
                true)
    end

    private

    def do_action(action, params = {}, cleanurl = false)
      action = '/' + action.to_s
      unless @session_id.nil?
        params['session-id'] = @session_id
        action = '/ctrl-int/1' + action unless cleanurl
      end
      params['hsgid'] = @hsgid unless @hsgid.nil?
      result = @client.get do |request|
        request.url action
        request.params = params
        request.headers.merge!(DEFAULT_HEADERS)
      end

      parse_result result
    end

    def parse_result(result)
      if !result.success?
        raise DACPForbiddenError.new(result)
      elsif result.headers['Content-Type'] == 'application/x-dmap-tagged'
        DMAPParser.parse(result.body)
      else
        result.body
      end
    end
  end

  # This error is raised if the DACP resource returns forbidden or
  # service unavailable
  class DACPForbiddenError < StandardError
    attr_reader :result
    def initialize(result)
      @result = result
    end
  end
end
