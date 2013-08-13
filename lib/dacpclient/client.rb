require 'rubygems'
require 'bundler'
Bundler.setup(:default)
require 'digest'
require 'net/http'
require 'dacpclient/pairingserver'
require 'dacpclient/dmapparser'
require 'dacpclient/dmapbuilder'
require 'uri'
require 'cgi'

module DACPClient
  class Client

    def initialize(name, host = 'localhost', port = 3689)
      @client = Net::HTTP.new(host, port)
      @name = name
      @host = host
      @port = port
      @service = nil
      @session_id = nil
      @mediarevision = 1
    end

    def pair(pin = nil)
      pairingserver = PairingServer.new(@name, '0.0.0.0', 1024)
      pairingserver.pin = pin unless pin.nil?
      pairingserver.start
    end

    def self.get_guid(name)
       d = Digest::SHA2.hexdigest(name)
       d[0..15]
    end

    def serverinfo
      do_action('server-info')
    end

    def login(pin = nil)
      response = do_action(:login, { 'pairing-guid' => '0x' + Client.get_guid(@name) })
      @session_id = response[:mlid]
      response
    rescue DACPForbiddenError => e
      puts "#{e.result.message} error: Cannot login, starting pairing process"
      pin = 4.times.map { Random.rand(10) } if pin.nil?
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

    def seek(ms)
      do_action(:setproperty, 'dacp.playingtime' => ms)
    end

    def status(wait = false)
      revision = wait ? @mediarevision : 1
      result = do_action(:playstatusupdate, 'revision-number' => revision)
      @mediarevision = result[:cmsr]
      result
    rescue Net::ReadTimeout => e
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

    def get_volume
      response = do_action(:getproperty, properties: 'dmcp.volume')
      response[:cmvo]
    end

    def set_volume(volume)
      do_action(:setproperty, 'dmcp.volume' => volume)
    end

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
      do_action('ctrl-int', {}, false)
    end

    def logout
      do_action(:logout, {}, false)
    end

    def queue(id)
      do_action 'playqueue-edit', { command: 'add', query: "\'dmap.itemid:#{id}\'" }
    end

    def clear_queue
      do_action 'playqueue-edit', { command: 'clear' }
    end

    def list_queue
      do_action 'playqueue-contents', {}
    end

    def databases
      do_action 'databases', {}, true
    end

    def playlists(db)
      do_action "databases/#{db}/containers", {}, true
    end

    def artwork(database, id, width = 320, height = 320)
      do_action "databases/#{database}/items/#{id}/extra_data/artwork", { mw: width, mh: height }, true
    end

    def now_playing_artwork(width = 320, height = 320)
      do_action :nowplayingartwork, { mw: width, mh: height }
    end

    def search(db, container, search)
      words = search.split
      queries = []
      queries.push(words.map { |v| "\'dmap.itemname:*#{v}*\'" }.join('+'))
      # queries.push(words.map{|v| "\'daap.songartist:*#{v}*\'"}.join('+'))
      query = '(' + queries.map { |q| "(#{q})" }.join(',') + ')'
      do_action "databases/#{db}/containers/#{container}/items", { type: 'music', sort: 'album', meta: 'dmap.itemid,dmap.itemname,daap.songartist,daap.songalbum', query: query }, true
    end

    private

    def do_action(action, params = {}, cleanurl = false)
      action = '/' + action.to_s
      unless @session_id.nil?
        params['session-id'] = @session_id
        action = '/ctrl-int/1' + action unless cleanurl
      end
      params = URI.encode_www_form(params)
      uri = URI::HTTP.build({ host: @host, port: @port, path: action, query: params })
      req = Net::HTTP::Get.new(uri.request_uri)
      req.add_field('Viewer-Only-Client', '1')
      res = Net::HTTP.new(uri.host, uri.port).start do |http|
        http.read_timeout = 1000
        http.request(req)
      end
      if res.kind_of?(Net::HTTPServiceUnavailable) || res.kind_of?(Net::HTTPForbidden)
        raise DACPForbiddenError.new(res)
      elsif !res.kind_of?(Net::HTTPSuccess)
        warn 'No succes!'
        warn res
        return nil
      end

      if res['Content-Type'] == 'application/x-dmap-tagged'
        DMAPParser.parse(res.body)
      else
        res.body
      end
    end
  end

  class DACPForbiddenError < StandardError
    attr_reader :result
    def initialize(res)
      @result = res
    end
  end
end
