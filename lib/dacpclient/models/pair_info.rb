module DACPClient
  class PairInfo < Model
    dmap_tag :cmpa

    dmap_attribute :pairing_code, :cmpg
    dmap_attribute :name, :cmnm
    dmap_attribute :type, :cmty

    # DMAPParser::Builder.cmpa do
    #   cmpg pair
    #   cmnm name
    #   cmty device_type
    # end.to_dmap
  end
end
