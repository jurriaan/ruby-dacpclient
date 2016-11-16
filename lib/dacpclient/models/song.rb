module DACPClient
  class Song < Model
    dmap_tag :mlit
    dmap_attribute :item_id, :miid
    dmap_attribute :name, :minm
    dmap_attribute :artist, :asar
    dmap_attribute :album, :asal
  end
end
