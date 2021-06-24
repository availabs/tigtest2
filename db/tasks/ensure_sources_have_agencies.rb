agency = Agency.where(name: "NYMTC").first_or_create
Source.all.each { |source| source.update_attribute(:agency_id, agency.id) if source.agency.nil? }
