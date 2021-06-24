# The BootstrapBreadcrumbsBuilder is a Bootstrap compatible breadcrumb builder.
# It provides basic functionalities to render a breadcrumb navigation according to Bootstrap's conventions.
#
# BootstrapBreadcrumbsBuilder accepts a limited set of options:
# * separator: what should be displayed as a separator between elements
#
# You can use it with the :builder option on render_breadcrumbs:
#     <%= render_breadcrumbs :builder => ::BootstrapBreadcrumbsBuilder, :separator => "&raquo;" %>
#
# Note: You may need to adjust the autoload_paths in your config/application.rb file for rails to load this class:
#     config.autoload_paths += Dir["#{config.root}/lib/"]
#
class BootstrapBreadcrumbsBuilder < BreadcrumbsOnRails::Breadcrumbs::Builder
  def render
    @context.content_tag(:div, class: 'breadcrumb') do
      @elements.collect do |element|
        render_element(element)
      end.join.html_safe
    end
  end
 
  def render_element(element)
    path = compute_path(element)
    name = compute_name(element)
    current = @context.current_page?(path)
    current_user = @context.current_user
    view = element.options[:view]
    query = element.options[:query]
    source = element.options[:source]
    action = element.options[:action]
    element.options[:title] = "Return to #{name}"
    
    @context.content_tag(:div, :class => "#{current ? 'active' : ''} breadcrumb_link") do
      if view
        menu_link_or_text = @context.content_tag(:span, class: 'dropdown') do
          button = @context.content_tag(:button,
                               class: "btn dropdown-toggle breadcrumb-menu btn-sm btn-default",
                               title: "#{name == view.name && view.source ? "Select to change view" : "Select to change application"}",
                               data: {toggle: 'dropdown'}) do
            "#{name == view.name && view.source ? view.source.name : name} #{@context.content_tag(:b, '', class: 'caret')}".html_safe
          end
          menu = @context.content_tag(:ul, id:'actionDropdown', class: 'dropdown-menu breadcrumb-menu', role: 'menu') do
            if source
              source.views.order(:name).collect do |view|
                if view.actions.include? action.to_s
                  if action.to_s == "view_metadata"
                    view_path = "#{@context.view_path(view)}/metadata#{'?' unless query.blank?}#{query}"
                  elsif action.to_s == "edit_metadata"
                    view_path = "#{@context.view_path(view)}/edit#{'?' unless query.blank?}#{query}"
                  elsif action.to_s == "upload"
                    view_path = "/uploads/new?view=#{view.id}"
                  else
                    view_path = "#{@context.view_path(view)}/#{action}#{'?' unless query.blank?}#{query}"
                  end
                else
                  view_path = @context.sources_path
                end
                if action.to_s == "edit_metadata"
                  if current_user
                    if current_user.has_role?(:admin)
                      @context.content_tag(:li, @context.link_to(view.name, (view_path) + "?admin=true"))
                    elsif view.contributors.include?(current_user)
                      @context.content_tag(:li, @context.link_to(view.name, (view_path) + "?contributor=true"))
                    elsif view.librarians.include?(current_user)
                      @context.content_tag(:li, @context.link_to(view.name, (view_path) + "?librarian=true"))
                    else
                      nil # @context.content_tag(:li, @context.link_to(view.name, view_path))
                    end
                  end
                else
                  @context.content_tag(:li, @context.link_to(view.name, view_path))
                end
              end.join.html_safe
            else
              view.actions.collect do |action|
                if action.to_s == "view_metadata"
                  action_path = "#{@context.view_path(view)}/metadata#{'?' unless query.blank?}#{query}"
                elsif action.to_s == "edit_metadata"
                  action_path = "#{@context.view_path(view)}/edit#{'?' unless query.blank?}#{query}"
                elsif action.to_s == "upload"
                  action_path = "/uploads/new?view=#{view.id}"
                elsif action.to_s == "copy"
                  if current_user
                    if current_user.has_role?(:admin)
                      action_path = "/views/new?view_id=#{view.id}&source_id=#{view.source.id}&admin=true"
                    elsif current_user.has_role?(:contributor)
                      action_path = "/views/new?view_id=#{view.id}&source_id=#{view.source.id}&contributor=true"
                    elsif current_user.has_role?(:librarian)
                      action_path = "/views/new?view_id=#{view.id}&source_id=#{view.source.id}&librarian=true"
                    else
                      action_path = "/views/new?view_id=#{view.id}&source_id=#{view.source.id}"
                    end
                  end
                else
                  action_path = "#{@context.view_path(view)}/#{action}#{'?' unless query.blank?}#{query}"
                end
                if action.to_s == "edit_metadata"
                  if current_user
                    if current_user.has_role?(:admin)
                      @context.content_tag(:li, @context.link_to(action.titleize, (action_path + "?admin=true")))
                    elsif view.contributors.include?(current_user)
                      @context.content_tag(:li, @context.link_to(action.titleize, (action_path + "?contributor=true")))
                    elsif view.librarians.include?(current_user)
                      @context.content_tag(:li, @context.link_to(action.titleize, (action_path + "?librarian=true")))
                    else
                      nil # @context.content_tag(:li, @context.link_to(action.titleize, action_path))
                    end
                  end
                elsif action.to_s == "upload"
                  if current_user && current_user.has_any_role?(:admin, :contributor, :librarian)
                    @context.content_tag(:li, @context.link_to(action.titleize, action_path))
                  end
                elsif action.to_s == "copy"
                  if current_user && current_user.has_any_role?(:admin, :contributor, :librarian)
                    @context.content_tag(:li, @context.link_to(action.titleize, action_path))
                  end
                elsif action.to_s == "watch"  
                  @context.content_tag(:li, @context.link_to(action.titleize, action_path)) if current_user
                else
                  @context.content_tag(:li, @context.link_to(action.titleize, action_path))
                end
              end.join.html_safe
            end
          end
          button + menu
        end
      else
        menu_link_or_text = @context.link_to_unless_current(name, path, element.options)
      end
      
      # divider = @context.content_tag(:span, (@options[:separator]  || '/').html_safe, :class => 'divider') unless current
      menu_link_or_text
    end
  end
end
