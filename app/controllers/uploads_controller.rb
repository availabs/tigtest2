class UploadsController < ApplicationController

  before_action :enforce_access
  before_action :enforce_new_access, only: [:new]
  before_action :enforce_view_access, only: [:show, :queue, :reset]
  
  ATTRIBUTES = {
      last_error: nil,
      progress_stage: 'stage',
      percentage: 50
    }

  def index
    view_id = params[:view]
    source_id = params[:source]

    if current_user
      agency_user_ids = current_user.agency.users.pluck(:id) if current_user.agency
      admin_ids = User.with_role(:admin).pluck(:id)
      ids = ((agency_user_ids || []) + admin_ids).uniq

      if view_id
        @uploads = Upload.where(view: view_id)
      elsif source_id
        @uploads = Upload.where(source: source_id)
      else
        if current_user.has_role?(:admin)
          @uploads = Upload.all
        elsif current_user.has_role?(:agency_admin) 
          @uploads = Upload.where(user: [ids])
        elsif current_user.has_role?(:librarian)
          @uploads = Upload.where("view_id in (?) or source_id in (?)", current_user.views.pluck(:id), current_user.sources.pluck(:id)).distinct
        end
      end
    end

    if view_id
      view = View.find_by_id(view_id)
      add_breadcrumb view.name, "/views/#{view_id}/metadata", view: view, source: view.source, action: :view_metadata
    elsif source_id
      source = Source.find_by_id(source_id)
      add_breadcrumb source.name, "/sources/#{source_id}", source: source, action: :view_metadata  
    end

    add_breadcrumb 'Uploads'
  end

  def new
    @remote_storage = ENV["FILEPICKER_ENABLED"] == 'true'
    @upload = @upload || Upload.new
    
    prepare_upload

    add_breadcrumb 'Add Upload'

    respond_to do |format|
      format.html # new.html.slim
      format.json { render json: @source }
    end
  end

  def new_help
    @remote_storage = ENV["FILEPICKER_ENABLED"] == 'true'
    @upload = @upload || Upload.new
    add_breadcrumb 'Update Help'
    @extensions = 'docx,htm,html'
    
    respond_to do |format|
      format.html # new_help.html.slim
      format.json { render json: @source }
    end
  end

  def create
    @remote_storage = ENV["FILEPICKER_ENABLED"] == 'true'
    
    @upload = Upload.new(params[:upload])
    unless @remote_storage
      upload_to_local_storage
    end

    if @upload.s3_location.present?
      @view = @upload.view
      @source = @upload.source

      if @view
        @upload.status = :available if @view.data_model.respond_to?(:process_upload)
      elsif @source
        @upload.status = :available if @source.uploadable?
      else
        # Assume help upload and figure out what type
        if @upload.filename.include? '.docx'
          @upload.status = :help_doc
        elsif @upload.filename.include? '.htm'
          @upload.status = :help_html
        end
      end
    end

    respond_to do |format|
      if @upload.save
        if @view
          alert_admins_to_contribution(@upload)
          format.html { redirect_to @upload.view, notice: 'File sucessfully uploaded.' }
          format.json { render json: @upload, status: :created, location: @upload.view }
        elsif @source
          alert_admins_to_contribution(@upload)
          format.html { redirect_to @source, notice: 'File sucessfully uploaded.' }
          format.json { render json: @upload, status: :created, location: @source }
        else
          format.html { redirect_to sources_path, notice: 'Help File sucessfully updated.' }
          format.json { render json: @upload, status: :created }
        end
      else

        format.html { 
          prepare_upload
          (@view || @source) ? render(action: 'new') : render(action: 'new_help') 
        }
        format.json { render json: @upload.errors, status: unprocessable_entity }
      end
    end
  end

  def show
    @upload = Upload.find(params[:id])
    @job = @upload.delayed_job

    set_action
    
    if @upload.view
      view = @upload.view
      add_breadcrumb view.name, "/views/#{view.id}/metadata", view: view, source: view.source, action: :view_metadata
      add_breadcrumb 'Show Upload', "/uploads/#{@upload.id}", view: view
    elsif @upload.source
      source = @upload.source
      add_breadcrumb source.name, "/sources/#{source.id}", source: source, action: :view_metadata
      add_breadcrumb 'Show Upload', "/uploads/#{@upload.id}", source: source
    end
      
    # if @upload.status == :processing
    #   Rails.logger.debug 'redirecting'
    #   redirect_to queue_upload_path(@upload)
    #   return
    # end
  end
   
  def status
    # Rails.logger.debug GC.stat

    job_id = Upload.where(id: params[:id]).pluck(:delayed_job_id).first
    return head(:gone) unless Delayed::Job.exists?(job_id)

    last_error, progress_stage, progress_current, progress_max =
      Delayed::Job.where(id: job_id)
        .pluck(:last_error, :progress_stage, :progress_current, :progress_max)[0]
    
    percentage  = (progress_max.nil? || progress_max.zero?) ? 0 : progress_current / progress_max.to_f * 100
    
    ATTRIBUTES[:last_error] = last_error
    ATTRIBUTES[:progress_stage] = progress_stage
    ATTRIBUTES[:percentage] = percentage

    render json: ATTRIBUTES
    # Rails.logger.debug GC.stat
  end
  
  def queue
    @upload = Upload.find(params[:id])
    @job = Delayed::Job.enqueue UploadJob.new(@upload), queue: 'uploads'

    @upload.update_attribute(:status, :queued)
    @upload.update_attribute(:delayed_job, @job)

    set_action

    respond_to do |format|
      format.js
    end

  end

  def destroy
    @upload = Upload.find(params[:id])
    @upload.destroy

    redirect_to(uploads_path)
  end


  def reset
    @upload = Upload.find(params[:id])
    job = @upload.delayed_job
    job.destroy if job
    
    @upload.update_attribute(:status, :available)
    
    redirect_to upload_path(@upload)
  end

  protected
  
  def set_action
    # available, error -process> queued
    # queued -remove> available
    # processing -stop> available
    # processed, display data
    @has_action = true
    @processed = false
    
    @remote = false

    case @upload.status.to_sym
    when :available, :error
      @action_name = 'Process'
      @action_link = queue_upload_path(@upload)
      @remote = true
      @message = "Processing will take a significant amount of time to complete."
    when :queued
      @action_name = 'Remove'
      @action_link = reset_upload_path(@upload)
      @message = "This action will prevent processing from completing."
    when :processing
      @action_name = 'Stop'
      @action_link = reset_upload_path(@upload)
      @message = "This action will prevent processing from completing."
    when :processed
      @processed = true
      @action_name = 'Reset'
      @action_link = reset_upload_path(@upload)

      @data_count =
        if @upload.view
          view = @upload.view
          if view.data_model.respond_to? :from_partition
            view.data_model
              .from_partition(@upload.year, @upload.month)
              .where(view: view).count
          elsif view.columns.include? 'year'
            view.data_model.where(view: view, year: @upload.year).count
          else
            view.data_model.where(view: view).count
          end
        else
          source = @upload.source
          # TODO: currently only support SED
          if source && source.data_model
            source.data_model.where(view: source.views).count
          end
        end
      
      @message = "This action will result in removal of data."
    else
      @has_action = false
    end
  end

  def enforce_access
      unless user_signed_in? && current_user.has_any_role?(:admin, :librarian, :contributor, :agency_admin)
        redirect_to (request.env["HTTP_REFERER"] || sources_path),
                    alert: "You are not permitted to view this information."
      end
  end

  def enforce_new_access
    if params[:view].present?
      @view = @view || View.find(params[:view]) 
      possibly_redirect @view
    else
      @source = @source || Source.find(params[:source]) if params[:source].present?
      possibly_redirect @source
    end
    
  end

  def enforce_view_access
    @upload = Upload.find(params[:id])
    possibly_redirect(@upload.view || @upload.source)
  end

  def possibly_redirect(uploadable)
    unless uploadable && (current_user.has_role?(:admin) ||
                     uploadable.librarians.include?(current_user) ||
                     uploadable.contributors.include?(current_user) ||
                     (current_user.has_role?(:agency_admin) &&
                      (uploadable.is_a?(View) ? uploadable.source.agency : uploadable.agency) == current_user.agency))
      redirect_to (request.env["HTTP_REFERER"] || sources_path),
                  alert: "You are not permitted to view this information."
    end
  end

  def prepare_upload
    if @view
      @hide_year = true if [RtpProject, TipProject, ComparativeFact].include?(@view.data_model)
      @show_months = @view.facts_have_month?
      @extensions = @view.upload_extensions || 'csv,zip'
    elsif @source
      @extensions = @source.upload_extensions || 'xlsx,zip'
    end
  end

  def upload_to_local_storage
    require 'fileutils'

    file = params[:upload][:s3_location]

    if file.present?
      begin
        @upload.size_in_bytes = File.size(file.path)
        @upload.filename = file.original_filename
        dir = @upload.local_storage_dir
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
        FileUtils.mv(file.path, "#{dir}/#{@upload.filename}" )
        @upload.s3_location = @upload.local_storage_url
      rescue => ex 
        Rails.logger.debug ex.message
        @upload.s3_location = nil
      end
    else
      @upload.s3_location = nil
    end
  end
end
