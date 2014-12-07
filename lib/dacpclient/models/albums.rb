module DACPClient
  class Albums < Model
    dmap_tag :agal
    dmap_attribute :status, :mstt
    dmap_attribute :update_type, :muty
    dmap_attribute :container_count, :mtco
    dmap_attribute :returned_count, :mrco
    dmap_container :items, :mlcl, DACPClient::Album
  end
end
