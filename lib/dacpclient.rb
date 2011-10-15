require 'digest'
require 'net/http'
require './lib/pairingserver'
require './lib/dmapparser'
require './lib/dmapbuilder'
require 'uri'
require 'cgi'

class DACPClient
  
  def initialize name, host = 'localhost', port = 3689
    @client = Net::HTTP.new host, port
    @name = name
    @host = host
    @port = port
    @service = nil
    @session_id = nil
  end
  
  def pair pin = nil
    pairingserver = PairingServer.new @name, '0.0.0.0', 1024
    pairingserver.pin = pin if !pin.nil?
    pairingserver.start
  end
  
  def self.getGUID name 
     d = Digest::SHA2.hexdigest name
     d[0..15]
  end
  
  def serverinfo
    do_action 'server-info'
  end
  
  def login
    response = do_action :login, {'pairing-guid' => '0x'+ DACPClient::getGUID(@name)}
    @session_id = response[:mlid]
  rescue DACPForbiddenError=>e
    puts "#{e.result.message} error: Cannot login, starting pairing process"
    pair
    retry
  end
  
  def content_codes
    do_action 'content-codes', {}, true
  end
  
  def play
    do_action :play
  end
  
  def playpause
    do_action :playpause
  end
  
  def stop
    do_action :stop
  end
  
  def pause 
    do_action :pause
  end
  
  def status 
    do_action :playstatusupdate, {'revision-number' => 1}
  end
  
  def next
    do_action :nextitem
  end
  
  def prev
    do_action :previtem
  end
  
  def get_volume
    response = do_action :getproperty, {properties: 'dmcp.volume'}
    response[:cmvo]
  end
  
  def set_volume volume
    do_action :setproperty, {'dmcp.volume' => volume}
  end
  
  def ctrl_int
    do_action 'ctrl-int',{},false
  end
  
  def logout
    do_action :logout, {}, false
  end
  
  private
  
  def do_action action, params = {}, cleanurl = false 
    action = '/'+action.to_s
    if !@session_id.nil?
      params['session-id'] = @session_id
      action = '/ctrl-int/1'+action unless cleanurl
    end
    params = params.map{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join '&'
    uri = URI::HTTP.build({host: @host, port: @port, path: action, query:params})
    p uri
    req = Net::HTTP::Get.new(uri.request_uri)
    req.add_field 'Viewer-Only-Client', '1'
    res = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
    if res.kind_of? Net::HTTPServiceUnavailable or res.kind_of? Net::HTTPForbidden
      raise DACPForbiddenError.new res
    elsif !res.kind_of? Net::HTTPSuccess 
      p res
      return nil
    end
    DMAPParser.parse res.body
  end
end
class DACPForbiddenError < StandardError
  attr :result
  def initialize res
    @result = res
  end
end
