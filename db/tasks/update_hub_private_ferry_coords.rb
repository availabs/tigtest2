private_ferry_mode = TransitMode.where(name: 'Private Ferry').first

if private_ferry_mode
  private_ferry_data = CountFact.where(transit_mode: private_ferry_mode)

  # east 34st pier for Queens sector
  first_rec = private_ferry_data.where(sector: Sector.where(name: 'Queens')).first
  if first_rec && first_rec.location
    first_rec.location.update_attributes(latitude: 40.743889, longitude: -73.970833)
  end

  # pier 11 for Brooklyn sector
  first_rec = private_ferry_data.where(sector: Sector.where(name: 'Brooklyn')).first
  if first_rec && first_rec.location
    first_rec.location.update_attributes(latitude: 40.703056, longitude: -74.006111)
  end

  # an arbitrary location between west 39th st (pier 79) and BPC/WFC for New Jersey sector
  first_rec = private_ferry_data.where(sector: Sector.where(name: 'New Jersey')).first
  if first_rec && first_rec.location
    first_rec.location.update_attributes(latitude: 40.744656, longitude: -74.016953)
  end
end