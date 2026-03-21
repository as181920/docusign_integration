# config valid for current version and patch releases of Capistrano
lock "~> 3.20.0"

set :application, "docusign_integration"
set :repo_url, "git@example.com:your-group/docusign-integration.git" # TODO: replace with real git repo

# Default branch is :main
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

append :linked_files, "config/database.yml", "config/local_env.yml", "config/master.key"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage", ".bundle"

set :keep_assets, 2
set :keep_releases, 5

set :rails_env, "production"
set :bundle_flags, "--verbose"

set :puma_systemctl_user, :user # :system
set :solid_queue_systemctl_user, :user # :system
set :solid_queue_role, :worker
