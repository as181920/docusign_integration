# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Git SCM
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Rails deployment integrations
require "capistrano/rvm"
require "capistrano/bundler"
require "capistrano/rails"

# Puma + Systemd
require "capistrano/puma"
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

# Solid Queue systemd service
require "capistrano/solid_queue"
install_plugin Capistrano::SolidQueue::Systemd

# Cron (optional, via schedule.rb)
require "whenever/capistrano"

# Custom tasks
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
