module DACPClient
  class Status < Model
    dmap_tag :cmst
    dmap_attribute :media_revision, :cmsr
    dmap_attribute :status_code, :mstt
    dmap_attribute :play_status, :caps
    dmap_attribute :shuffle_state, :cash
    dmap_attribute :repeat_state, :carp
    dmap_attribute :fullscreen, :cafs
    dmap_attribute :visualizer, :cavs
    dmap_attribute :volume_controllable, :cavc
    dmap_attribute :album_shuffle, :caas
    dmap_attribute :album_repeat, :caar
    dmap_attribute :fullscreen_enabled, :cafe
    dmap_attribute :visualizer_enabled, :cave
    dmap_attribute :track_id, :canp
    dmap_attribute :title, :cann
    dmap_attribute :artist, :cana
    dmap_attribute :album, :canl
    dmap_attribute :album_id, :asai
    dmap_attribute :media_kind, :cmmk
    dmap_attribute :song_time, :astm
    dmap_attribute :song_length, :cast
    dmap_attribute :song_remaining_time, :cant

    def song_position
      return 0 unless song_length? && song_remaining_time?
      song_length - song_remaining_time
    end

    def stopped?
      play_status == 2
    end

    def playing?
      play_status == 4
    end

    def paused?
      !stopped? && !playing?
    end
    # casu (dacp.su: byte): 0
  end
end
