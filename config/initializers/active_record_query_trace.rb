if Rails.env.development?
  ActiveRecordQueryTrace.enabled = true
  ActiveRecordQueryTrace.level = :full # default

  # Optional: other gem config options go here
end
