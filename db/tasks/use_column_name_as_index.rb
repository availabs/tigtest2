# Previous commit uses integer as default_column_index in symbology model
# its value comes from column.id
# this brings instability in future snapshot restoration
# We decided to use column.name as column_index

Symbology.all.each do | sym |
  if sym.default_column_index
    # find column based on previous default_column_index value (based on column.id)
    col = Column.where(id: sym.default_column_index).first
    if col 
      # if column is found, then use its name to update symbology.default_column_index
      sym.update_attributes(default_column_index: col.name)
    end
  end
end
