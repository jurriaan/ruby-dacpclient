module DACPClient
  class Album < Model
    dmap_tag :mlit
    dmap_attribute :item_id, :miid
    dmap_attribute :name, :minm
    dmap_attribute :count, :mimc
    dmap_attribute :album_artist, :asaa
    dmap_attribute :persistent_id, :mper
  end
end
