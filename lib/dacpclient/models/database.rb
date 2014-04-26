module DACPClient
  class Database < Model
    dmap_tag :mlit
    dmap_attribute :item_id, :miid
    dmap_attribute :name, :minm
    dmap_attribute :count, :mimc
    dmap_attribute :container_count, :mctc
    dmap_attribute :default_db, :mdbk
    dmap_attribute :persistent_id, :mper
  end
end
