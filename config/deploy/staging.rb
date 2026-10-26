set :application, "docusign_integration_staging"
set :branch, :main

# rvm config
set :rvm_type, :user
set :rvm_ruby_version, "ruby-4.0.9"
set :rvm_ruby_string, :local

# puma config
set :puma_bind, %W[unix:///opt/www/#{fetch(:application)}/shared/tmp/sockets/puma.sock]
set :puma_threads, [2, 5]
set :puma_workers, 1
set :puma_preload_app, false
set :puma_env, "production"
set :puma_service_unit_name, "puma_#{fetch(:application)}"

# solid_queue config
set :solid_queue_service_unit_name, "solid_queue_#{fetch(:application)}"

# server config
set :deploy_to, "/opt/www/#{fetch(:application)}"
server "docusign.code-li.cn", user: "deployer", roles: %w[app web db batch worker]
