ENV_CONFIG = Rails.root.join("config/local_env.yml").then do |env_file|
  File.readable?(env_file) ? Hash(YAML.load_file(env_file, aliases: true)[Rails.env]) : {}
end

class ENVConfig
  ENV_CONFIG.each do |key, value|
    const_set key.upcase, value
  end

  class << self
    ENV_CONFIG.each do |key, value|
      define_method(key.to_sym) { value }
    end

    def method_missing(_method_sym, *_arguments, &)
      nil
    end

    def respond_to_missing?(symbol, _include_private)
      ENV_CONFIG.key?(symbol.to_s)
    end
  end
end

Rails.application.configure do
  MissionControl::Jobs.http_basic_auth_user = ENV.fetch("basic_auth_username", nil)
  MissionControl::Jobs.http_basic_auth_password = ENV.fetch("basic_auth_password", nil)
end

ActsAsTaggableOn.tags_table = "aato_tags"
ActsAsTaggableOn.taggings_table = "aato_taggings"

if defined?(BetterHtml)
  BetterHtml.configure do |config|
    config.template_exclusion_filter = proc { |filename| !filename.start_with?(Rails.root.to_s) }
  end
end

Ransack.configure do |c|
  c.postgres_fields_sort_option = :nulls_always_last
end

class ActsAsTaggableOn::Tag
  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end

InlineSvg.configure do |config|
  config.asset_finder = InlineSvg::PropshaftAssetFinder
end

Rails.application.config.action_cable.disable_request_forgery_protection = true
