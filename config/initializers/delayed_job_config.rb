Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_run_time = 6.hours
# Force log level
Rails.application.config.log_level = :info
# Rails.logger = Logger.new(STDERR)
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
