class AddBaseGeometryRefToBaseOverlays < ActiveRecord::Migration
  def up
    add_reference :base_overlays, :base_geometry, index: true
    #data-migration
    BaseGeometry.all.each do |r|
      if r.base_overlay_id
        overlay = BaseOverlay.find(r.base_overlay_id)
        if overlay
          overlay.update_attribute(:base_geometry_id, r.id)
        end
      end
    end

    remove_reference :base_geometries, :base_overlay
  end

  def down
    add_reference :base_geometries, :base_overlay, index: true
    #data-migration
    BaseOverlay.all.each do |r|
      if r.base_geometry
        r.base_geometry.update_attribute(:base_overlay_id, r.id)
      end
    end

    remove_reference :base_overlays, :base_geometry
  end
end
