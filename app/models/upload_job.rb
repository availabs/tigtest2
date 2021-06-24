class UploadJob < ProgressJob::Base
  require 'open-uri'
  
  def initialize(upload)
    super()
    @upload = upload
  end

  def set_progress(value)
    @job.update_column(:progress_current, value)
  end
  
  def perform
    # check status, handle if invalid

    @upload.update_attribute(:status, :processing)
    # create file stream
    update_stage('downloading file')
    file = open(URI.encode(@upload.public_path), {
                  content_length_proc: lambda {|length| update_progress_max(length)},
                  progress_proc: lambda {|size| set_progress(size)}
                })
                
    # handle errors
    begin
      update_stage('downloaded file')
      # call process
      ext = File.extname(@upload.filename)
      update_stage('expanding') if ext == '.zip'
      line_count = 0
      
      delegate(file, ext) do |stage, count|
        Delayed::Worker.logger.debug("Stellar: #{stage}")
        return unless Delayed::Job.exists?(@job)
        
        case stage
        when 'count'
          update_stage('counted')
          update_progress_max(count)
          line_count = count
          set_progress(0)
        when 'processing'
          update_stage('processing')
          if line_count && count
            update_stage("processed #{count}/#{line_count}")
            set_progress(count)
          end
        when 'create_many'
          update_stage("processed #{count}/#{line_count}")
          set_progress(count)
        when 'processed'
          @upload.update_attribute(:status, :processed)
        when 'counting'
          update_stage("#{count} rows")
        else
          update_stage(stage)
          if line_count && count
            set_progress(count)
          end
        end
      end
    ensure
      file.close! if file.respond_to?(:close!)
    end
  end

  def delegate(file, ext, &block)
    if @upload.view
      @upload.view.data_model.process_upload(file, @upload.view, @upload.year, @upload.month, ext, &block)
    else
      if @upload.source.default_data_model == 'DemographicFact'
        @upload.source.data_model.process_source_upload(file, @upload.source, @upload.year, @upload.to_year, @upload.geometry_version, @upload.data_level, ext, &block)
      end
    end
  end
end
