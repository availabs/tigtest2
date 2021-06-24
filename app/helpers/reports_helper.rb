module ReportsHelper
  def new_records_since(model, date_string)
    model.where('created_at >= ?', date_string).count
  end

  def sources_contributed_to(user_id)
    Source.select("sources.id, sources.name").joins(:contributors).group("sources.id").where(contributors_sources: {user_id: user_id})
  end

  def views_contributed_to(user_id)
    View.select("views.id, views.name, views.data_levels, views.value_columns").joins(:contributors).group("views.id").where(contributors_views: {user_id: user_id})
  end

  def librarian_sources(user_id)
    Source.select("sources.id, sources.name").joins(:librarians).group("sources.id").where(librarians_sources: {user_id: user_id})
  end

  def librarian_views(user_id)
    View.select("views.id, views.name, views.data_levels, views.value_columns").joins(:librarians).group("views.id").where(librarians_views: {user_id: user_id})
  end

  def top_contributors
    top_contributor_array = []
    contributor_names = User.with_role(:contributor).map(&:display_name)
    contributor_sources = User.with_role(:contributor).map{ |user| sources_contributed_to(user.id).size }.map(&:size)
    contributor_views = User.with_role(:contributor).map{ |user| views_contributed_to(user.id).size }.map(&:size)
    
    contributor_names.each_with_index do |user, idx|
      top_contributor_array << [user, contributor_sources[idx] + contributor_views[idx]]
    end

    top_contributor_array = top_contributor_array.sort_by{ |a,b| b }.reverse.unshift(['User', 'No. Sources & Views'])
    top_contributor_array
  end

  def top_librarians
    top_librarian_array = []
    librarian_names = User.with_role(:librarian).map(&:display_name)
    librarian_sources = User.with_role(:librarian).map{ |user| librarian_sources(user.id).size }.map(&:size)
    librarian_views = User.with_role(:librarian).map{ |user| librarian_views(user.id).size }.map(&:size)
    
    librarian_names.each_with_index do |user, idx|
      top_librarian_array << [user, librarian_sources[idx] + librarian_views[idx]]
    end

    top_librarian_array = top_librarian_array.sort_by{ |a,b| b }.reverse.unshift(['User', 'No. Sources & Views'])
    top_librarian_array
  end
end
