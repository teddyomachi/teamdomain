# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.1'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

namespace :deploy do
  desc "Bundle install under current directory."
  task :bundle_files do
    on roles(:app) do
      execute "cd #{current_path} && bin/bundle install --deployment --binstubs && bin/bundle exec rails webpacker:install && bin/bundle exec webpack"
      # execute "cd #{current_path} && bundle exec rails webpacker:install && bundle exec webpack"
    end
  end
end