require 'digest'
require 'uri'
require 'plist'
require 'dmapparser'
require 'faraday'
require 'dacpclient/faraday/flatter_params_encoder'
require 'dacpclient/faraday/gzip'
require 'dacpclient/pairingserver'
require 'dacpclient/browser'
require 'dacpclient/version'
require 'dacpclient/model'
require 'dacpclient/models/status'
require 'dacpclient/models/pair_info'
require 'dacpclient/models/playlist'
require 'dacpclient/models/playlists'
require 'dacpclient/models/play_queue_item'
require 'dacpclient/models/play_queue'

module DACPClient
  # The Client class handles communication with the server
  class Client
    attr_accessor :hsgid
    attr_writer :guid
    attr_reader :name, :host, :port, :session_id

    DEFAULT_HEADERS = {
      'Viewer-Only-Client' => '1',
      'Accept-Encoding' => 'gzip',
      'Connection' => 'keep-alive',
      'User-Agent' => 'RubyDACPClient/' + VERSION
    }.freeze

    def initialize(name, host = 'localhost', port = 3689)
      @name = name
      @host = host
      @port = port

      @session_id = nil
      @hsgid = nil
      @media_revision = 1
      setup_connection
    end

    [:play, :playpause, :stop, :pause,
     :nextitem, :previtem, :getspeakers].each do |action_name|
      define_method action_name do
        do_action action_name
      end
    end

    alias_method :previous, :previtem
    alias_method :prev, :previtem
    alias_method :next, :nextitem
    alias_method :speakers, :getspeakers

    def guid
      return @guid unless @guid.nil?
      d = Digest::SHA2.hexdigest(@name)
      d[0..15].upcase
    end

    def pair(pin)
      pairingserver = PairingServer.new(name, guid)
      pairingserver.pin = pin
      pairingserver.start
    end

    def serverinfo
      do_action('server-info', clean_url: true)
    end

    def login
      response = nil
      if @hsgid.nil?
        pairing_guid = '0x' + guid
        response = do_action(:login,  :'pairing-guid' => pairing_guid)
      else
        response = do_action(:login, hasFP: 1)
      end
      @session_id = response[:mlid]
      response
    end

    def pair_and_login(pin = nil)
      login
    rescue DACPForbiddenError, Faraday::ConnectionFailed => e
      pin = 4.times.map { Random.rand(10) } if pin.nil?
      if e.instance_of? DACPForbiddenError
        message = e.result.status
      else
        message = e
      end
      warn "#{message} error: Cannot login, starting pairing process"
      warn "Pincode: #{pin}"
      @host = pair(pin).host
      setup_connection
      retry
    end

    def content_codes
      do_action('content-codes', clean_url: true)
    end

    def track_length
      response = do_action(:getproperty, properties: 'dacp.playingtime')
      response.cast? ? response['cast'] : 0
    end

    def seek(ms)
      set_property('dacp.playingtime', ms)
    end

    def position
      response = do_action(:getproperty, properties: 'dacp.playingtime')
      response.cast? ? (response['cast'] - response['cant']) : 0
    end

    alias_method :position=, :seek

    def status(wait = false)
      revision = wait ? @media_revision : 1
      result = do_action(:playstatusupdate, :'revision-number' => revision,
                                            model: Status)
      @media_revision = result.media_revision
      result
    rescue Faraday::Error::TimeoutError => e
      if wait
        retry
      else
        raise e
      end
    end

    def volume
      response = do_action(:getproperty, properties: 'dmcp.volume')
      response[:cmvo]
    end

    def volume=(volume)
      set_property('dmcp.volume', volume)
    end

    def repeat
      response = do_action(:getproperty, properties: 'dacp.repeatstate')
      response[:carp]
    end

    def repeat=(repeatstate)
      set_property('dacp.repeatstate', repeatstate)
    end

    def shuffle
      response = do_action(:getproperty, properties: 'dmcp.shufflestate')
      response[:cash]
    end

    def shuffle=(shufflestate)
      set_property('dmcp.shufflestate', shufflestate)
    end

    def ctrl_int
      do_action('ctrl-int', clean_url: true)
    end

    def logout
      do_action(:logout)
      @media_revision = 1
      @session_id = nil
    end

    def queue(id)
      do_action('playqueue-edit', command: 'add',
                                  query: "\'dmap.itemid:#{id}\'")
    end

    def clear_queue
      do_action('playqueue-edit', command: 'clear')
    end

    def list_queue
      do_action('playqueue-contents', model: PlayQueue)
    end

    def databases
      do_action('databases', clean_url: true)
    end

    def playlists(db = default_db)
      do_action("databases/#{db.miid}/containers", clean_url: true,
                                                   model: Playlists).items
    end

    def default_db
      databases.mlcl.to_a.find { |item| item.mdbk == 1 }
    end

    def default_playlist(db = default_db)
      playlists(db).find { |item| item.base_playlist? }
    end

    def artwork(database, id, width = 320, height = 320)
      url = "databases/#{database}/items/#{id}/extra_data/artwork"
      do_action(url, { mw: width, mh: height }, clean_url: true)
    end

    def now_playing_artwork(width = 320, height = 320)
      do_action(:nowplayingartwork, mw: width, mh: height)
    end

    def search(search, type = nil, db = default_db,
               container = default_playlist(default_db))
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
      q = '(' + q + ')' if queries.length > 1
      meta  = %w(dmap.itemname dmap.itemid com.apple.itunes.has-chapter-data
                 daap.songalbum com.apple.itunes.cloud-id dmap.containeritemid
                 com.apple.itunes.has-video com.apple.itunes.itms-songid
                 com.apple.itunes.extended-media-kind dmap.downloadstatus
                 daap.songdisabled daap.songhasbeenplayed daap.songbookmark
                 com.apple.itunes.is-hd-video daap.songlongcontentdescription
                 daap.songtime daap.songuserplaycount daap.songartist
                 com.apple.itunes.content-rating daap.songdatereleased
                 com.apple.itunes.movie-info-xml daap.songalbumartist
                 com.apple.itunes.extended-media-kind).join(',')
      url = "databases/#{db.miid}/containers/#{container.miid}/items"
      do_action(url, { query: q, type: 'music', sort: 'album', meta: meta,
                       :'include-sort-headers' => 1 }, clean_url: true)
    end

    private

    def setup_connection
      @uri = URI::HTTP.build(host: @host, port: @port)
      Faraday::Utils.default_params_encoder = Faraday::FlatterParamsEncoder
      @client = Faraday.new(@uri.to_s)
      @client.use FaradayMiddleware::Gzip
    end

    def set_property(property, value)
      do_action(:setproperty, property => value)
    end

    def do_action(action, clean_url: false, model: nil, **params)
      action = '/' + action.to_s
      unless @session_id.nil?
        params['session-id'] = @session_id.to_s
        action = '/ctrl-int/1' + action unless clean_url
      end
      params['hsgid'] = @hsgid unless @hsgid.nil?

      result = @client.get do |request|
        request.options.params_encoder = Faraday::FlatterParamsEncoder
        request.url action
        request.params = params
        request.headers.merge!(DEFAULT_HEADERS)
      end

      parse_result result, model
    end

    def parse_result(result, model)
      if !result.success?
        fail DACPForbiddenError, result
      elsif result.headers['Content-Type'] == 'application/x-dmap-tagged'
        res = DMAPParser::Parser.parse(result.body)
        model ? model.new(res) : res
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
