source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "4.0.9"

gem "rails", "~> 8.1.4"
gem "rails-i18n", "~> 8.0"
gem "rack-cors", require: "rack/cors"
gem "pg", "~> 1.6"
gem "bcrypt", "~> 3.1"
gem "jbuilder"
gem "propshaft"
gem "image_processing"
gem "ruby-vips"
gem "puma", "~> 8.0"
gem "whenever", require: false
gem "faraday"
gem "pundit"
gem "audited"
gem "ransack", "~> 6.0", ">= 6.0.1"
gem "rucaptcha"
gem "acts-as-taggable-on"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "mission_control-jobs"

gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]
gem "ip_info", git: "git@gitlab.dd-life.com:shared/ip_info.git", branch: "master"

gem "omni_account", git: "git@gitlab.dd-life.com:shared/omni_account.git", branch: "master"
gem "omni_pay", git: "git@gitlab.dd-life.com:shared/omni_pay.git", branch: "master"
gem "omni_region", git: "git@gitlab.dd-life.com:shared/omni_region.git", branch: "master"
gem "omni_role", git: "git@gitlab.dd-life.com:shared/omni_role.git", branch: "master"

gem "wechat_open_platform_proxy", git: "git@gitlab.dd-life.com:weixin.open/wechat_open_platform_proxy.git", branch: "master"
gem "wechat_vendor_platform_proxy", git: "git@gitlab.dd-life.com:weixin.pay/wechat_vendor_platform_proxy.git", branch: "master"
gem "wechat_work_platform_proxy", git: "git@gitlab.dd-life.com:weixin.work/wechat_work_platform_proxy.git", branch: "master"

gem "easy_style", git: "git@gitlab.dd-life.com:corp.front_end/easy_style_engine.git", branch: "main"
gem "anonymous_authorization", git: "git@gitlab.dd-life.com:shared/anonymous_authorization.git", branch: "main"
gem "user_auth", git: "git@gitlab.dd-life.com:shared/user_auth.git", branch: "main"
gem "tenant_auth", git: "git@gitlab.dd-life.com:shared/tenant_auth.git", branch: "main"
gem "organization_auth", git: "git@gitlab.dd-life.com:shared/organization_auth.git", branch: "main"
gem "short_url", git: "git@gitlab.dd-life.com:common_utility/short_url.git", branch: "master"

group :development, :test do
  gem "mocha", require: false
  gem "factory_bot_rails"
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "guard"
  gem "guard-bundler"
  gem "guard-minitest"
  gem "guard-rake"
  gem "guard-rubocop"
  gem "bundler-audit", require: false
  gem "capistrano", require: false
  gem "capistrano3-puma", github: "seuros/capistrano-puma", require: false
  gem "capistrano-bundler", require: false
  gem "capistrano-rails", require: false
  gem "capistrano-rvm", require: false
  gem "capistrano-solid_queue", require: false
  gem "rubocop", require: false
  gem "rubocop-erb", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-rake", require: false
  gem "web-console"
end
