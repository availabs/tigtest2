module ApplicationHelper

  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  def format_date_time(datetime)
    return datetime.strftime("%I:%M %p %b %d %Y") unless datetime.nil?
  end

  def format_user_field(label, value)

    html = "<div class='row'>"
    value = (value.nil? || value.blank?) ? 'N/A' : value

    if label.split(' ').count == 1
      html << "<div class='col-xs-1' style='padding:5px 5px;border-bottom:1px solid #679D89'>"
      html << "<strong>"
      html << label
      html << "</strong>"
      html << "</div>"
      html << "<div class='col-xs-11 text-right' style='padding:5px 5px;border-bottom:1px solid #679D89'>"
      html << value
      html << "</div>"
      html << "</div>"
    else
      html << "<div class='col-xs-4' style='padding:5px 5px;border-bottom:1px solid #679D89'>"
      html << "<strong>"
      html << label
      html << "</strong>"
      html << "</div>"
      html << "<div class='col-xs-8 text-right' style='padding:5px 5px;border-bottom:1px solid #679D89'>"
      html << value
      html << "</div>"
      html << "</div>"
    end

    return html.html_safe

  end

  def unswitched?
    (params[:switch].nil?) || (params[:switch] == 'false')
  end

  def url_with_protocol(url)
    /^http/i.match(url) ? url : "http://#{url}"
  end

  def agency_fields
    html = '<hr><div class="row toParse">'

    html << '<input id="access_control_XXX_agency_id" name="access_control[XXX][agency_id]" type="hidden" value="">'
    html << '<input id="access_control_XXX_source_id" name="access_control[XXX][source_id]" type="hidden" value="' + (params[:source] || '') + '">'
    html << '<input id="access_control_XXX_view_id" name="access_control[XXX][view_id]" type="hidden" value="' + (params[:view] || '') + '">'
    html << '<input id="access_control_XXX_role" name="access_control[XXX][role]" type="hidden" value="agency">'

    html << '<div class="agencyLabel col-sm-3 text-left"><h4><a class="removeAgency"><i class="fa fa-times-circle"></i></a> ...</h4></div>'

    html << '<div class="control-group boolean optional access_control_XXX_show col-sm-3 text-center">'
    html << '<div class="controls">'
    html << '<input name="access_control[XXX][show]" type="hidden" value="0">'
    html << '<input class="boolean optional" id="access_control_XXX_show" name="access_control[XXX][show]" type="checkbox" value="1">'
    html << '</div>' #controls
    html << '</div>' #controlGroup

    html << '<div class="control-group boolean optional access_control_XXX_download col-sm-3 text-center">'
    html << '<div class="controls">'
    html << '<input name="access_control[XXX][download]" type="hidden" value="0">'
    html << '<input class="boolean optional" id="access_control_XXX_download" name="access_control[XXX][download]" type="checkbox" value="1">'
    html << '</div>' #controls
    html << '</div>' #controlGroup

    html << '<div class="control-group boolean optional access_control_XXX_comment col-sm-3 text-center">'
    html << '<div class="controls">'
    html << '<input name="access_control[XXX][comment]" type="hidden" value="0">'
    html << '<input class="boolean optional" id="access_control_XXX_comment" name="access_control[XXX][comment]" type="checkbox" value="1">'
    html << '</div>' #controls
    html << '</div>' #controlGroup

    html << '</div>' # toParse

    return html.html_safe
  end

  def user_field
    html = '<div class="row toParse">'

    html << '<input id="access_control_user_XXX_user_id" name="access_control[user_XXX][user_id]" type="hidden" value="">'
    html << '<input id="access_control_user_XXX_source_id" name="access_control[user_XXX][source_id]" type="hidden" value="' + (params[:source] || '') + '">'
    html << '<input id="access_control_user_XXX_view_id" name="access_control[user_XXX][view_id]" type="hidden" value="' + (params[:view] || '') + '">'
    html << '<input id="access_control_user_XXX_role" name="access_control[user_XXX][role]" type="hidden" value="agency">'

    html << '<div class="userLabel col-sm-3 text-right"><h5><a class="removeUser"><i class="fa fa-times-circle"></i></a> ...</h5></div>'

    html << '<div class="control-group boolean optional access_control_user_XXX_show col-sm-3 text-center">'
    html << '<div class="controls">'
    html << '<input name="access_control[user_XXX][show]" type="hidden" value="0">'
    html << '<input class="boolean optional" id="access_control_user_XXX_show" name="access_control[user_XXX][show]" type="checkbox" value="1">'
    html << '</div>' #controls
    html << '</div>' #controlGroup

    html << '<div class="control-group boolean optional access_control_user_XXX_download col-sm-3 text-center">'
    html << '<div class="controls">'
    html << '<input name="access_control[user_XXX][download]" type="hidden" value="0">'
    html << '<input class="boolean optional" id="access_control_user_XXX_download" name="access_control[user_XXX][download]" type="checkbox" value="1">'
    html << '</div>' #controls
    html << '</div>' #controlGroup

    html << '<div class="control-group boolean optional access_control_user_XXX_comment col-sm-3 text-center">'
    html << '<div class="controls">'
    html << '<input name="access_control[user_XXX][comment]" type="hidden" value="0">'
    html << '<input class="boolean optional" id="access_control_user_XXX_comment" name="access_control[user_XXX][comment]" type="checkbox" value="1">'
    html << '</div>' #controls
    html << '</div>' #controlGroup

    html << '</div>' # toParse

    return html.html_safe
  end

  def determine_most_powerful_role(current_user)
    if current_user.has_role?(:admin)
      'Admin'
    elsif current_user.has_role?(:agency_admin)
      'Agency Admin'
    elsif current_user.has_role?(:librarian)
      'Librarian'
    elsif current_user.has_role?(:contributor)
      'Contributor'
    elsif current_user.has_role?(:agency_user)
      'Agency User'
    else
      'Public User'
    end
  end

  def can_process_uploads(user, uploadable)
    user && uploadable && ( user.has_role?(:admin) ||
      uploadable.librarians.include?(user) ||
      (
        user.has_role?(:agency_admin) && 
        (
          (uploadable.is_a?(View) ? uploadable.source.agency : uploadable.agency ) == user.agency
        )
      ))
  end

  def can_view_uploads(user, uploadable)
    user && uploadable && ( user.has_role?(:admin) ||
      uploadable.librarians.include?(user) ||
      uploadable.contributors.include?(user) ||
      (
        user.has_role?(:agency_admin) && 
        (
          (uploadable.is_a?(View) ? uploadable.source.agency : uploadable.agency ) == user.agency
        )
      ))
  end

  def upload_button_text(upload)
    case upload.status.to_sym
    when :available, :error
      text = "Process"
      remote = true
      link = queue_upload_path(upload)
    when :queued
      text = "Remove" # returns to "available" 
      link = reset_upload_path(upload)
    when :processing
      text = "Stop" # returns to "available"
      link = reset_upload_path(upload)
    when :processed
      text = "Reset" # returns to "available"
      link = reset_upload_path(upload)
    end

    return [text, remote, link]
  end

  def add_default_access_controls(obj)
    if obj.class == View
      AccessControl.create(view_id: obj.id, show: false, download: false, comment: false) # Guest User
      AccessControl.create(view_id: obj.id, role: "public", show: true, download: false, comment: false) # Public User
      AccessControl.create(view_id: obj.id, role: "agency", show: true, download: true, comment: true) # Agency User
    else
      AccessControl.create(source_id: obj.id, show: false, download: false, comment: false) # Guest User
      AccessControl.create(source_id: obj.id, role: "public", show: true, download: false, comment: false) # Public User
      AccessControl.create(source_id: obj.id, role: "agency", show: true, download: true, comment: true) # Agency User
    end
  end

  def upload_file_public_url(upload)
    file_path = upload.s3_location
    if file_path.to_s.starts_with?('uploads')
      "#{root_url}#{file_path}"
    else
      file_path
    end
  end

  def html_help_path
    help_upload = Upload.help_html.order(:updated_at).last
    help_upload ? upload_file_public_url(help_upload) : '/GatewayHelp.htm'
  end

  def user_name_or_email(user)
    if user
      user.display_name.blank? ? user.email : user.display_name
    else
      'Deleted User'
    end
  end

  def source_formatted_disclaimer(source)
    simple_format(auto_link(source.disclaimer, sanitize: false), {}, sanitize: false).html_safe if source && source.disclaimer.present?
  end

  def format_as_text(text)
    simple_format(auto_link(text, sanitize: false), {}, sanitize: false).html_safe if text.present?
  end
end
