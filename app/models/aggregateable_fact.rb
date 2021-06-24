module AggregateableFact
  
  # Utility method for doing detect when Array may or may not have nested Enumerables
  def detect_2_levels item, match
    if item.is_a? Array
      item.detect do |item_element|
        item_element == match
      end
    else
      item == match
    end
  end

  def get_join_levels(view, aggregate_level, area_filter)
    raise "View #{view} does not have data_hierarchy defined, required for aggregation" unless view.data_hierarchy
    # find the first aggregation hierarchy that includes the desired aggregate level
    # (and possibly filter level)
    area_filter_level = area_filter && area_filter.type
    hierarchy = view.data_hierarchy.detect do |dh|
      al = dh.detect do |dhe|
        detect_2_levels(dhe, aggregate_level)
      end
      fl = if area_filter_level
        dh.detect do |dhe|
          detect_2_levels(dhe, area_filter_level)
        end
      end
      if area_filter_level
        al && fl
      else
        al
      end
    end
    raise "View #{view} does not support aggregate_level #{aggregate_level} and/or filter level #{area_filter_level}" unless hierarchy

    # how many levels of join?
    join_levels = agg_join_index = hierarchy.index_with_sub(aggregate_level)

    if area_filter
      filter_join_index = hierarchy.index_with_sub(area_filter.type)
      join_levels = [join_levels, filter_join_index].max
    end
    [join_levels, agg_join_index, filter_join_index]
  end

end
