require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module DocusignIntegration
  class Application < Rails::Application
    config.before_configuration do
      env_file = Rails.root.join("config/local_env.yml")
      if File.file?(env_file)
        YAML.load_file(env_file, aliases: true)[Rails.env].to_h.each do |key, value|
          ENV[key.to_s] = value.to_s
        end
      end
    end

    config.load_defaults Rails::VERSION::STRING.to_f

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "Beijing"
    config.i18n.default_locale = :"zh-CN"
    config.i18n.available_locales = %i[zh-CN en]
    config.i18n.fallbacks = { "zh-CN" => [:"zh-CN", :en], en: [:en, :"zh-CN"] }

    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { database: { writing: :queue } }
    config.solid_cache.connects_to = { database: { writing: :cache } }

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "*", headers: :any, methods: %i[get post delete put patch options head]
      end
    end

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("action_mailer_smtp_address", nil),
      port: ENV.fetch("action_mailer_smtp_port", nil),
      domain: ENV.fetch("action_mailer_smtp_domain", nil),
      user_name: ENV.fetch("action_mailer_smtp_user_name", nil),
      password: ENV.fetch("action_mailer_smtp_password", nil),
      authentication: "plain"
    }

    config.generators do |g|
      g.orm             :active_record
      g.template_engine :erb
      g.stylesheets     false
      g.javascripts     false
      g.helper          false
      g.test_framework  :test_unit
      g.skip_routes     true
      g.system_tests    nil
    end
  end
end
