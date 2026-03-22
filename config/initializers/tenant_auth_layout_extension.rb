Rails.application.config.to_prepare do
  Dir.glob(Rails.root.join("app/extensions/**/*_extension*.rb")).sort.each do |file|
    require_dependency file
  end
end
