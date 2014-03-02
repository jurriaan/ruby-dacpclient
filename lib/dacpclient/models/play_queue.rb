module DACPClient
  class PlayQueue < Model
    dmap_tag :ceQR
    dmap_attribute :status, :mstt
    dmap_attribute :container_count, :mtco
    dmap_attribute :shuffle_mode, :apsm
    dmap_attribute :repeat_mode, :aprm
    # ceQu (unknown (1): unknown): 0
    dmap_container :items, :mlcl, DACPClient::PlayQueueItem
  end
end
