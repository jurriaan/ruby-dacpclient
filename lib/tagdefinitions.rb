class DMAPParser
  
  Tag = Struct.new :type, :value do
    def inspect level = 0
      "#{'  '*level}#{type}: #{value}"
    end
    def to_dmap
      value = self.value
      value = case type.type
      when :container
        value.inject('') { |ret,val| ret += val.to_dmap }
      when :byte
        DMAPConverter.byte_to_bin value
      when :uint16, :short
        DMAPConverter.short_to_bin value
      when :uint32
        DMAPConverter.int_to_bin value
      when :uint64
        DMAPConverter.long_to_bin value
      when :bool
        DMAPConverter.bool_to_bin value
      when :hex
        DMAPConverter.hex_to_bin value
      when :string
        value
      when :date 
        DMAPConverter.int_to_bin value.to_i
      when :version
        DMAPConverter.version_to_bin value.to_i
      else
        puts "Unknown type #{tag.type}"
        #Tag.new tag, parseunknown(data)
        value
      end
      type.tag.to_s + [value.length].pack('N') + value
    end
  end
  
  class TagContainer < Tag
    
    def initialize type = nil, value = []
      super type, value
    end
    
    def inspect level = 0
      "#{'  '*level}#{type}:\n" +value.inject('') { |ret,val| ret + val.inspect(level + 1).chomp() + "\n" } 
    end
    
    def get_value key
      val= if key.is_a? Symbol 
        value.find {|val| val.type.tag == key}
      else
        value.find {|val| val.type.name == key}
      end
      if val.type.type == :container
        val
      else
        val.value
      end
    end
    
    alias :[] :get_value

    def has? key
      val = if key.is_a? Symbol 
        value.find {|val| val.type.tag == key}
      else
        value.find {|val| val.type.name == key}
      end
      !val.nil?
    end
    
    def method_missing method, *arguments, &block
      value.each do |dmap|
        if dmap.type.tag == method
          return dmap.value
        end
      end
      super
    end
  end
      
  
  TagDefinition = Struct.new :tag, :type, :name do
    def inspect
      "#{tag} (#{name}: #{type})"
    end
    def to_s
      "#{tag} (#{name}: #{type})"
    end
  end
  
  # Sources:
  # https://github.com/chendo/dmap-ng/blob/master/lib/dmap/tag_definitions.rb
  # https://code.google.com/p/ytrack/wiki/DMAP
  # https://code.google.com/p/tunesremote-se/wiki/ContentCodes
  # /content-codes
  Types = [
  TagDefinition.new(:mcon, :container, 'dmap.container'), 
  TagDefinition.new(:msrv, :container, 'dmap.serverinforesponse'), 
  TagDefinition.new(:msml, :container, 'dmap.msml'), 
  TagDefinition.new(:mccr, :container, 'dmap.contentcodesresponse'), 
  TagDefinition.new(:mdcl, :container, 'dmap.dictionary'), 
  TagDefinition.new(:mlog, :container, 'dmap.loginresponse'), 
  TagDefinition.new(:mupd, :container, 'dmap.updateresponse'), 
  TagDefinition.new(:avdb, :container, 'daap.serverdatabases'), 
  TagDefinition.new(:mlcl, :container, 'dmap.listing'), 
  TagDefinition.new(:mlit, :container, 'dmap.listingitem'), 
  TagDefinition.new(:mbcl, :container, 'dmap.bag'), 
  TagDefinition.new(:adbs, :container, 'daap.returndatabasesongs'), 
  TagDefinition.new(:aply, :container, 'daap.databaseplaylists'), 
  TagDefinition.new(:apso, :container, 'daap.playlistsongs'), 
  TagDefinition.new(:mudl, :container, 'dmap.deletedidlisting'), 
  TagDefinition.new(:abro, :container, 'daap.databasebrowse'), 
  TagDefinition.new(:abal, :container, 'daap.browsealbumlisting'),
  TagDefinition.new(:abar, :container, 'daap.browseartistlisting'),
  TagDefinition.new(:abcp, :container, 'daap.browsecomposerlisting'), 
  TagDefinition.new(:abgn, :container, 'daap.browsegenrelisting'), 
  TagDefinition.new(:prsv, :container, 'daap.resolve'), 
  TagDefinition.new(:arif, :container, 'daap.resolveinfo'),
  TagDefinition.new(:casp, :container, 'dacp.speakers'),
  TagDefinition.new(:caci, :container, 'dacp.controlint'),
  TagDefinition.new(:cmpa, :container, 'dacp.pairinganswer'),
  TagDefinition.new(:cacr, :container, 'dacp.cacr'),
  TagDefinition.new(:cmcp, :container, 'dmcp.controlprompt'),  
  TagDefinition.new(:cmgt, :container, 'dmcp.getpropertyresponse'),
  TagDefinition.new(:cmst, :container, 'dmcp.status'),
  TagDefinition.new(:agal, :container, 'daap.albumgrouping'),
  TagDefinition.new(:minm, :string, 'dmap.itemname'), 
  TagDefinition.new(:msts, :string, 'dmap.statusstring'), 
  TagDefinition.new(:mcna, :string, 'dmap.contentcodesname'), 
  TagDefinition.new(:asal, :string, 'daap.songalbum'), 
  TagDefinition.new(:asaa, :string, 'daap.songalbumartist'), 
  TagDefinition.new(:asar, :string, 'daap.songartist'), 
  TagDefinition.new(:ascm, :string, 'daap.songcomment'), 
  TagDefinition.new(:asfm, :string, 'daap.songformat'), 
  TagDefinition.new(:aseq, :string, 'daap.songeqpreset'), 
  TagDefinition.new(:asgn, :string, 'daap.songgenre'), 
  TagDefinition.new(:asdt, :string, 'daap.songdescription'), 
  TagDefinition.new(:asul, :string, 'daap.songdataurl'),
  TagDefinition.new(:ceWM, :string, 'com.apple.itunes.welcome-message'), # not a official name?
  TagDefinition.new(:ascp, :string, 'daap.songcomposer'), 
  TagDefinition.new(:assu, :string, 'daap.sortartist'), 
  TagDefinition.new(:assa, :string, 'daap.sortalbum'), 
  TagDefinition.new(:agrp, :string, 'daap.songgrouping'), 
  TagDefinition.new(:cann, :string, 'daap.nowplayingtrack'), 
  TagDefinition.new(:cana, :string, 'daap.nowplayingartist'), 
  TagDefinition.new(:canl, :string, 'daap.nowplayingalbum'), 
  TagDefinition.new(:cang, :string, 'daap.nowplayinggenre'),
  TagDefinition.new(:cmnm, :string, 'dacp.devicename'),
  TagDefinition.new(:cmty, :string, 'dacp.devicetype'),
  TagDefinition.new(:cmpg, :hex, 'dacp.pairingguid'), # hex string
  TagDefinition.new(:mper, :uint64, 'dmap.persistentid'),
  TagDefinition.new(:canp, :uint64, 'dacp.nowplaying'),
  TagDefinition.new(:cmpy, :uint64, 'dacp.passguid'),
  TagDefinition.new(:mstt, :uint32, 'dmap.status'), # http status?? 
  TagDefinition.new(:mcnm, :uint32, 'dmap.contentcodesnumber'), 
  TagDefinition.new(:miid, :uint32, 'dmap.itemid'), 
  TagDefinition.new(:mcti, :uint32, 'dmap.containeritemid'), 
  TagDefinition.new(:mpco, :uint32, 'dmap.parentcontainerid'), 
  TagDefinition.new(:mimc, :uint32, 'dmap.itemcount'), 
  TagDefinition.new(:mrco, :uint32, 'dmap.returnedcount'), 
  TagDefinition.new(:mtco, :uint32, 'dmap.containercount'), 
  TagDefinition.new(:mstm, :uint32, 'dmap.timeoutinterval'), 
  TagDefinition.new(:msdc, :uint32, 'dmap.databasescount'),
  TagDefinition.new(:msma, :uint32, 'dmap.speakermachineaddress'),
  TagDefinition.new(:mlid, :uint32, 'dmap.sessionid'), 
  TagDefinition.new(:assr, :uint32, 'daap.songsamplerate'), 
  TagDefinition.new(:assz, :uint32, 'daap.songsize'), 
  TagDefinition.new(:asst, :uint32, 'daap.songstarttime'), 
  TagDefinition.new(:assp, :uint32, 'daap.songstoptime'), 
  TagDefinition.new(:astm, :uint32, 'daap.songtime'), 
  TagDefinition.new(:msto, :uint32, 'dmap.utcoffset'),
  TagDefinition.new(:cmsr, :uint32, 'dmcp.mediarevision'),
  TagDefinition.new(:caas, :uint32, 'dacp.albumshuffle'),
  TagDefinition.new(:caar, :uint32, 'dacp.albumrepeat'),
  TagDefinition.new(:cant, :uint32, 'dacp.remainingtime'),
  TagDefinition.new(:cmmk, :uint32, 'dmcp.mediakind'),
  TagDefinition.new(:cast, :uint32, 'dacp.tracklength'),
  TagDefinition.new(:asai, :uint32, 'daap.songalbumid'),
  TagDefinition.new(:aeNV, :uint32, 'com.apple.itunes.norm-volume'),
  TagDefinition.new(:cmvo, :uint32, 'dmcp.volume'),
  TagDefinition.new(:mcty, :uint16, 'dmap.contentcodestype'), 
  TagDefinition.new(:asbt, :uint16, 'daap.songsbeatsperminute'), 
  TagDefinition.new(:asbr, :uint16, 'daap.songbitrate'), 
  TagDefinition.new(:asdc, :uint16, 'daap.songdisccount'), 
  TagDefinition.new(:asdn, :uint16, 'daap.songdiscnumber'), 
  TagDefinition.new(:astc, :uint16, 'daap.songtrackcount'), 
  TagDefinition.new(:astn, :uint16, 'daap.songtracknumber'), 
  TagDefinition.new(:asyr, :uint16, 'daap.songyear'),
  TagDefinition.new(:ated, :uint16, 'daap.supportsextradata'),
  TagDefinition.new(:asgr, :uint16, 'daap.supportsgroups'),
  TagDefinition.new(:mikd, :byte, 'dmap.itemkind'), 
  TagDefinition.new(:casu, :byte, 'dacp.su'),
  TagDefinition.new(:msau, :byte, 'dmap.authenticationmethod'), 
  TagDefinition.new(:mstu, :byte, 'dmap.updatetype'), 
  TagDefinition.new(:asrv, :byte, 'daap.songrelativevolume'), 
  TagDefinition.new(:asur, :byte, 'daap.songuserrating'), 
  TagDefinition.new(:asdk, :byte, 'daap.songdatakind'),
  TagDefinition.new(:caps, :byte, 'dacp.playstatus'),
  TagDefinition.new(:cash, :byte, 'dacp.shufflestate'),
  TagDefinition.new(:carp, :byte, 'dacp.repeatstate'),
  TagDefinition.new(:muty, :byte, 'dmap.updatetype'),   
  TagDefinition.new(:"f\215ch", :byte, 'dmap.haschildcontainers'),
  TagDefinition.new(:msas, :byte, 'dmap.authenticationschemes'),
  TagDefinition.new(:cavs, :bool, 'dacp.visualizer'), # Source: https://code.google.com/p/tunesremote-plus/source/browse/trunk/src/org/tunesremote/daap/Status.java
  TagDefinition.new(:cafs, :bool, 'dacp.fullscreen'),
  TagDefinition.new(:ceGS, :bool, 'com.apple.itunes.genius-selectable'),
  TagDefinition.new(:mslr, :bool, 'dmap.loginrequired'), 
  TagDefinition.new(:msal, :bool, 'dmap.supportsautologout'), 
  TagDefinition.new(:msup, :bool, 'dmap.supportsupdate'), 
  TagDefinition.new(:mspi, :bool, 'dmap.supportspersistenids'), 
  TagDefinition.new(:msex, :bool, 'dmap.supportsextensions'), 
  TagDefinition.new(:msbr, :bool, 'dmap.supportsbrowse'), 
  TagDefinition.new(:msqy, :bool, 'dmap.supportsquery'), 
  TagDefinition.new(:msix, :bool, 'dmap.supportsindex'), 
  TagDefinition.new(:msrs, :bool, 'dmap.supportsresolve'), 
  TagDefinition.new(:asco, :bool, 'daap.songcompliation'), 
  TagDefinition.new(:asdb, :bool, 'daap.songdisabled'), 
  TagDefinition.new(:abpl, :bool, 'daap.baseplaylist'), 
  TagDefinition.new(:aeSP, :bool, 'com.apple.itunes.smart-playlist'),
  TagDefinition.new(:aePP, :bool, 'com.apple.itunes.is-podcast-playlist'),
  TagDefinition.new(:aePS, :bool, 'com.apple.itunes.special-playlist'),
  TagDefinition.new(:aeSG, :bool, 'com.apple.itunes.saved-genius'),
  TagDefinition.new(:aeFP, :bool, 'com.apple.itunes.req-fplay'),
  TagDefinition.new(:aeHV, :bool, 'com.apple.itunes.has-video'),
  TagDefinition.new(:caia, :bool, 'dacp.isavailiable'),
  TagDefinition.new(:ceVO, :bool, 'com.apple.itunes.voting-enabled'), # not an official name
  TagDefinition.new(:aeSV, :version, 'com.apple.itunes.music-sharing-version'),
  TagDefinition.new(:mpro, :version, 'dmap.protocolversion'), 
  TagDefinition.new(:apro, :version, 'daap.protocolversion'),
  TagDefinition.new(:musr, :version, 'dmap.serverrevision'),
  TagDefinition.new(:mstc, :date, 'dmap.utc-time'),
  TagDefinition.new(:asda, :date, 'daap.songdateadded'), 
  TagDefinition.new(:asdm, :date, 'daap.songdatemodified')
  
  ].freeze
end