module DACPClient
  class Songs < Model
    dmap_tag :apso
    dmap_attribute :status, :mstt
    dmap_attribute :update_type, :muty
    dmap_attribute :container_count, :mtco
    dmap_attribute :returned_count, :mrco
    dmap_container :items, :mlcl, DACPClient::Song
  end
end
