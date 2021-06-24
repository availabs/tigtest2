class AccessControl < ActiveRecord::Base
  belongs_to :view
  belongs_to :source
  attr_accessible(:source_id, :view_id, :agency_id, :user_id, :role, :show, :download, :comment)

  def self.viewable_sources(current_user)
    if current_user.nil? # Any User
      viewable = Source.includes(:comments).joins(:access_controls).where(access_controls: {role: nil, show: true})
      view_source_ids = AccessControl.joins(:view).where(role: nil, show: true).pluck("views.source_id").uniq
      viewable += Source.where(id: view_source_ids)
    else
      if current_user.has_role?(:admin)
        viewable = Source.all
      elsif current_user.has_role?(:public) && current_user.roles.count == 1 # Public User
        source_ids = AccessControl.joins(:source).where(role: "public", show: true).pluck(:source_id).uniq
        view_source_ids = AccessControl.joins(:view).where(role: "public", show: true).pluck("views.source_id").uniq

        viewable = Source.includes(:comments).where(id: (source_ids + view_source_ids).uniq)
      else # Agency User
        viewable_to_user = Source.includes(:comments).joins(:access_controls).where(access_controls: {user_id: current_user.id, show: true})
        not_viewable_to_user = Source.includes(:comments).joins(:access_controls).where(access_controls: {user_id: current_user.id, show: false})
        viewable_to_user_agency = Source.includes(:comments).joins(:access_controls).where(access_controls: {role: "agency", agency_id: current_user.agency_id, show: true}) if current_user.agency
        not_viewable_to_user_agency = Source.includes(:comments).joins(:access_controls).where(access_controls: {role: "agency", agency_id: current_user.agency_id, show: false}) if current_user.agency
        viewable_to_all_agencies = Source.includes(:comments).joins(:access_controls).where(access_controls: {role: "agency", agency_id: nil, show: true})
        viewable_to_user_but_not_user_agency = (not_viewable_to_user_agency & viewable_to_user)

        viewable = ((viewable_to_user || []) + (viewable_to_user_agency || []) + (viewable_to_all_agencies || [])) - ((not_viewable_to_user || []) + (not_viewable_to_user_agency || []))
        if viewable_to_user_but_not_user_agency
          viewable_to_user_but_not_user_agency.empty? ? viewable : (viewable += viewable_to_user_but_not_user_agency)
        end
        not_viewable = Source.all - viewable
        not_viewable.each do |source|
          # Add to viewable if viewable_views not empty
          viewable << source unless viewable_views(current_user, source).empty?
        end
      end
    end
    
    viewable.uniq.sort_by(&:name)
  end


  def self.viewable_views(current_user, source)
    viewable = []
    if current_user.try(:has_role?, :admin)
      viewable = source.views.includes(:comments)
    else 
      source.views.includes(:comments).each do |view|
        if view.access_controls.empty? # If the view doensn't have ACs
          if view.source.access_controls.empty? # If the source doesn't have ACs
            nil
          else # If the source has ACs
            viewable << determine_show_controls(current_user, view.source, view)
          end
        else # If the view has ACs
          viewable << determine_show_controls(current_user, nil, view)
        end
      end

      viewable = viewable.compact
    end
    
    viewable.uniq.sort_by(&:name)
  end


  def self.determine_show_controls(current_user, source=nil, view=nil)
    obj = source || view
    if current_user.nil? # Any User
      obj.access_controls.where(role: nil).first.try(:show) == true ? view : nil
    else
      if current_user.has_role?(:public) && current_user.roles.count == 1 # Public User
        if obj.access_controls.where(role: "public").empty?
          view
        else
          obj.access_controls.where(role: "public").first.try(:show) == true ? view : nil
        end
      else # Agency User
        if current_user.has_role?(:admin)
          #true
          view
        else
          viewable_for_user = obj.access_controls.where(user_id: current_user.id).first
          viewable_for_user_agency = obj.access_controls.where(role: "agency", agency_id: current_user.agency_id).first if current_user.agency
          viewable_for_all_agencies = obj.access_controls.where(role: "agency", agency_id: nil).first

          if viewable_for_user.nil?
            if viewable_for_user_agency.nil?
              if viewable_for_all_agencies.nil?
                nil
              else
                viewable_for_all_agencies.show == true ? view : nil
              end
            else
              viewable_for_user_agency.show == true ? view : nil
            end
          else
            viewable_for_user.show == true ? view : nil
          end
        end
      end
    end
  end


  def self.allow_for_download?(current_user, view)
    if current_user.nil? # Any User
      view.access_controls.find_by(role: nil).try(:download)
    else
      if view.access_controls.empty? # If the view doensn't have ACs
        if view.source.access_controls.empty? # If the source doesn't have ACs
          false
        else # If the source has ACs
          determine_download_controls(current_user, view.source)
        end
      else # If the view has ACs
        determine_download_controls(current_user, view)
      end
    end
  end


  def self.determine_download_controls(current_user, obj)
    if current_user.nil? # Any User
      obj.access_controls.find_by(role: nil).try(:download)
    else
      if current_user.has_role?(:public) && current_user.roles.count == 1 # Public User
        obj.access_controls.find_by(role: "public").try(:download)
      else # Agency User
        if current_user.has_role?(:admin)
          true
        else
          downloadable_for_user = obj.access_controls.where(user_id: current_user.id).first
          downloadable_for_user_agency = obj.access_controls.where(role: "agency", agency_id: current_user.agency_id).first if current_user.agency
          downloadable_for_all_agencies = obj.access_controls.where(role: "agency", agency_id: nil).first

          if downloadable_for_user.nil?
            if downloadable_for_user_agency.nil?
              downloadable_for_all_agencies.nil? ? false : downloadable_for_all_agencies.download
            else
              downloadable_for_user_agency.download
            end
          else
            downloadable_for_user.download
          end
        end
      end
    end
  end

  def self.allow_for_comment?(current_user, obj)
    if obj.class == Source
      obj.access_controls.empty? ? false : determine_comment_controls(current_user, obj)
    else
      if obj.access_controls.empty? 
        obj.source.access_controls.empty? ? false : determine_comment_controls(current_user, obj.source)
      else
        determine_comment_controls(current_user, obj)
      end
    end
  end

  def self.determine_comment_controls(current_user, obj)
    if current_user.nil? # Any User
      obj.access_controls.find_by(role: nil).try(:comment)
    else
      if current_user.has_role?(:public) && current_user.roles.count == 1 # Public User
        obj.access_controls.find_by(role: "public").try(:comment)
      else # Agency User
        if current_user.has_role?(:admin)
          true
        else
          commentable_for_user = obj.access_controls.where(user_id: current_user.id).first
          commentable_for_user_agency = obj.access_controls.where(role: "agency", agency_id: current_user.agency_id).first if current_user.agency
          commentable_for_all_agencies = obj.access_controls.where(role: "agency", agency_id: nil).first

          if commentable_for_user.nil?
            if commentable_for_user_agency.nil?
              commentable_for_all_agencies.nil? ? false : commentable_for_all_agencies.comment
            else
              commentable_for_user_agency.comment
            end
          else
            commentable_for_user.comment
          end
        end
      end
    end
  end

  def self.exist_for_object?(source_or_view, object=nil)
    if source_or_view.class == Source
      if object.class == Agency
        AccessControl.where(source_id: source_or_view.id, agency_id: object.id).count > 0
      elsif object.class == User # User
        AccessControl.where(source_id: source_or_view.id, user_id: object.id).count > 0
      elsif object.nil?
        AccessControl.where(source_id: source_or_view.id).count > 0
      end
    else # View
      if object.class == Agency
        AccessControl.where(view_id: source_or_view.id, agency_id: object.id).count > 0
      elsif object.class == User # User
        AccessControl.where(view_id: source_or_view.id, user_id: object.id).count > 0
      elsif object.nil?
        AccessControl.where(view_id: source_or_view.id).count > 0
      end
    end
  end
end
