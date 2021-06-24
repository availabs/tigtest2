class Road < ActiveRecord::Base
  def self.find_or_create_normalized(name, direction)
    roads = arel_table
    where(roads[:name].matches(name).or(roads[:number].matches(name)))
      .where(direction: direction).first || create(name: name.titleize, direction: direction)
  end
  
  def display_name
    return "#{name.to_s} (#{number.to_s})" if !name.blank? && !number.blank? && number != '0'
    return "#{name.to_s}" if !name.blank? 
    return "#{number.to_s}" if !number.blank? && number != '0'
    ''
  end
end
