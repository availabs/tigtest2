class AddBaseGeometryRefToAreas < ActiveRecord::Migration
  def up
    add_reference :areas, :base_geometry, index: true
    #data-migration
    BaseGeometry.all.each do |r|
      if r.area_id
        area = Area.find(r.area_id)
        if area
          area.update_attribute(:base_geometry_id, r.id)
        end
      end
    end

    remove_reference :base_geometries, :area
  end

  def down
    add_reference :base_geometries, :area, index: true
    #data-migration
    Area.all.each do |r|
      if r.base_geometry
        r.base_geometry.update_attribute(:area_id, r.id)
      end
    end

    remove_reference :areas, :base_geometry
  end
end
