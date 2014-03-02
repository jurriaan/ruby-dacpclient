module DACPClient
  class PlayQueueItem < Model
    dmap_tag :mlit
    dmap_attribute :track_id, :ceQs
    dmap_attribute :title, :ceQn
    dmap_attribute :artist, :ceQr
    dmap_attribute :album, :ceQa
    dmap_attribute :genre, :ceQg
    dmap_attribute :album_id, :asai

    dmap_attribute :media_kind, :cmmk
    dmap_attribute :song_time, :astm

    # aeGs (com.apple.itunes.can-be-genius-seed: bool): true
    # ceGS (com.apple.itunes.genius-selectable: bool): true
  end
end
