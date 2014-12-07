module DACPClient
  class Artist < Model
    dmap_tag :mlit
    dmap_attribute :item_id, :miid
    dmap_attribute :name, :minm
    dmap_attribute :count, :mimc
    dmap_attribute :album_count, :agac
    dmap_attribute :song_artist_id, :asri
    dmap_attribute :persistent_id, :mper
  end
end
