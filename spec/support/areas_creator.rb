class AreasCreator

  # We use this instead of factories because factories, by default, create new objects for associations,
  # and we need to use the same objects to set up the data structure. It can be done with factory_girl
  # but it's messy and you have to jump through hoops with a custom strategy.
  #
  # We could also probably load through CSV but I'm not sure there's a loader that handles this.

  def self.create_areas

    # NASSAU (Long Island)

    # TODO base_geometry_ids
    Area.where(name: "taz1623", type: Area::AREA_LEVELS[:taz], size: 3.338655, base_geometry_id: 2592).first_or_create
    Area.where(name: "taz1624", type: Area::AREA_LEVELS[:taz], size: 0.631877, base_geometry_id: 2593).first_or_create
    Area.where(name: "taz1625", type: Area::AREA_LEVELS[:taz], size: 2.989205, base_geometry_id: 2590).first_or_create

    Area.where(name: "long_island", type: Area::AREA_LEVELS[:subregion], size:  1196.77, base_geometry_id:  3623).first_or_create
    Area.where(name: "nybpm_counties", type: Area::AREA_LEVELS[:region], size:  nil, base_geometry_id:  nil).first_or_create
    Area.where(name: "nymtc_planning_area", type: Area::AREA_LEVELS[:region], size:  nil, base_geometry_id:  nil).first_or_create

    nassau = Area.where(name: "Nassau", type: Area::AREA_LEVELS[:county], size:  284.72, base_geometry_id:  19).first_or_create
    ['taz1623', 'taz1624', 'taz1625'].each do |a|
      nassau.enclosed_areas << Area.where(name: a) unless nassau.enclosed_areas.include?(Area.where(name: a)) 
    end

    ['long_island', 'nybpm_counties', 'nymtc_planning_area'].each do |a|
      nassau.enclosing_areas << Area.where(name: a) unless nassau.enclosed_areas.include?(Area.where(name: a)) 
    end

    # BERGEN (New Jersey)

    Area.where(name: "taz2661", type: Area::AREA_LEVELS[:taz], size: 3.126107, base_geometry_id: 2847).first_or_create
    Area.where(name: "taz2662", type: Area::AREA_LEVELS[:taz], size: 6.358476, base_geometry_id: 2740).first_or_create
    Area.where(name: "taz2663", type: Area::AREA_LEVELS[:taz], size: 2.891565, base_geometry_id: 2876).first_or_create
    Area.where(name: "new_jersey", type: Area::AREA_LEVELS[:subregion], size: 4389.64, base_geometry_id: 3621).first_or_create

    bergen = Area.where(name: "Bergen", type: Area::AREA_LEVELS[:county], size: 233.01, base_geometry_id: 4).first_or_create
    ['taz2661', 'taz2662', 'taz2663'].each do |a|
      bergen.enclosed_areas << Area.where(name: a) unless bergen.enclosed_areas.include?(Area.where(name: a)) 
    end

    # Note we use :nybpm_counties
    ['new_jersey', 'nybpm_counties'].each do |a|
      bergen.enclosing_areas << Area.where(name: a) unless bergen.enclosed_areas.include?(Area.where(name: a)) 
    end

    # ESSEX (New Jersey)

    Area.where(name: "taz2906", type: Area::AREA_LEVELS[:taz], size: 0.295915, base_geometry_id: 1164).first_or_create
    Area.where(name: "taz2907", type: Area::AREA_LEVELS[:taz], size: 0.134532, base_geometry_id: 702).first_or_create
    Area.where(name: "taz2908", type: Area::AREA_LEVELS[:taz], size: 0.068255, base_geometry_id: 703).first_or_create

    essex = Area.where(name: "Essex", type: Area::AREA_LEVELS[:county], size: 233.01, base_geometry_id: 4).first_or_create
    ['taz2906', 'taz2907', 'taz2908'].each do |a|
      essex.enclosed_areas << Area.where(name: a) unless essex.enclosed_areas.include?(Area.where(name: a)) 
    end

    # Note we use new_jersey and :nybpm_counties
    ['new_jersey', 'nybpm_counties'].each do |a|
      essex.enclosing_areas << Area.where(name: a) unless essex.enclosed_areas.include?(Area.where(name: a)) 
    end

    # FAIRFIELD (Connecticut)

    Area.where(name: "taz2450", type: Area::AREA_LEVELS[:taz], size: 4.365285, base_geometry_id: 3084).first_or_create
    Area.where(name: "taz2451", type: Area::AREA_LEVELS[:taz], size: 3.629375, base_geometry_id: 3094).first_or_create
    Area.where(name: "taz2452", type: Area::AREA_LEVELS[:taz], size: 3.704301, base_geometry_id: 2917).first_or_create

    Area.where(name: "connecticut", type: Area::AREA_LEVELS[:subregion], size: 4389.64, base_geometry_id: 3621).first_or_create
    fairfield = Area.where(name: "Fairfield", type: Area::AREA_LEVELS[:county], size: 233.01, base_geometry_id: 4).first_or_create
    ["taz2450", "taz2451", "taz2452"].each do |a|
      fairfield.enclosed_areas << Area.where(name: a) unless fairfield.enclosed_areas.include?(Area.where(name: a)) 
    end

    # Note we use :nybpm_counties
    ['connecticut', 'nybpm_counties'].each do |a|
      fairfield.enclosing_areas << Area.where(name: a) unless fairfield.enclosed_areas.include?(Area.where(name: a)) 
    end

  end

end
