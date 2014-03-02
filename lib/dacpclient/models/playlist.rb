module DACPClient
  class Playlist < Model
    dmap_tag :mlit
    dmap_attribute :item_id, :miid
    dmap_attribute :name, :minm
    dmap_attribute :base_playlist, :abpl
    dmap_attribute :count, :mimc
  end
end
