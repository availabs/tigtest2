module NamedValue
  def [](index)
    if index.is_a?(Integer)
      find(index).name
    else
      find_by_name(index).id
    end
  end
end
