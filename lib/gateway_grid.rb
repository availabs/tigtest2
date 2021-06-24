class GatewayGrid < PivotTable::Grid
  # Overrides some of the methods in PivotTable::Grid to "deal with the awful performance
  # once you start dealing with real data", as Scott said.
  def column_headers
    if (@column_headers.count == 0)
      @column_headers = headers @column_name
    else
      @column_headers
    end
  end

  def row_headers
    if (@row_headers.count == 0)
      @row_headers = headers @row_name
    else
      @row_headers
    end
  end

  def prepare_grid
    @column_headers = []
    @row_headers = []
    @data_grid = []
    @column_indexes = Hash.new
    @row_indexes = Hash.new
    row_headers.each_with_index do |row, row_index|
      @row_indexes[row] = row_index
      current_row = []
      column_headers.each_with_index do |col, col_index|
        @column_indexes[col] = col_index
        current_row << nil
      end
      @data_grid << current_row
    end
    @data_grid
  end

  def populate_grid
    prepare_grid
    @source_data.each do |item|
      row_index = @row_indexes[item.send(row_name)]
      col_index = @column_indexes[item.send(column_name)]

      row = @data_grid[row_index]
      row[col_index] = item
    end
    @data_grid
  end
end
