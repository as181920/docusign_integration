set :application, "docusign_integration_local"
set :branch, :main

# rvm config
set :rvm_type, :user
set :rvm_ruby_version, "3.4.5"
set :rvm_ruby_string, :local

# nginx config
set :nginx_server_name, "local.example.com" # TODO: replace
set :nginx_config_name, fetch(:application)
set :nginx_sites_available_path, "/opt/nginx/sites-available"
set :nginx_sites_enabled_path, "/opt/nginx/sites-enabled"

# puma config
set :puma_bind, %W[unix:///opt/www/#{fetch(:application)}/shared/tmp/sockets/puma.sock]
set :puma_threads, [2, 3]
set :puma_workers, 1
set :puma_preload_app, false
set :puma_env, "production"
set :puma_service_unit_name, "puma_#{fetch(:application)}"

# solid_queue config
set :solid_queue_service_unit_name, "solid_queue_#{fetch(:application)}"

# server config
set :deploy_to, "/opt/www/#{fetch(:application)}"
server "127.0.0.1", user: "deployer", roles: %w[app web db batch worker] # TODO: replace
