# config valid only for current version of Capistrano
lock "3.11.0"

set :application, 'secret_files'
set :deploy_user, 'teamdomain'

set :rails_env, 'production'
set :repo_url, "git@github.com:teddyomachi/secret-files.git"

# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.4'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

set :keep_releases, 3

# Default value for default_env is {}
set :default_env, { path: "/home/#{fetch(:deploy_user)}/.rbenv/shims:$PATH" }

set :passenger_restart_with_touch, true
 
set :tests, []

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   desc "Restart your application."
#   task :restart do
#     run "mkdir -p #{shared_path}/tmp"
#     run "touch #{shared_path}/tmp/restart.txt"
#   end
# end
namespace :deploy do
  desc "Restart your application."
  task :restart do
    on roles(:app) do
      execute "sudo /etc/init.d/httpd restart"
      # execute "mkdir -p #{shared_path}/tmp"
      # execute "touch #{shared_path}/tmp/restart.txt"
    end
  end

  desc "install bundle"
  task :bundle_install do
    on roles(:app) do
      execute "cd #{current_path};bundle install"
    end
  end
end
