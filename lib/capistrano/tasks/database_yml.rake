# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.1'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

namespace :deploy do
  desc "Upload database.yml to the shared/config directory."
  task :secrets_yml do
    on roles(:app) do
      unless test "[ -f #{shared_path}/config/database.yml ]"
        unless test "[ -d #{shared_path}/config ]"
          execute "/bin/mkdir -p #{shared_path}/config/"
        end
        upload! "config/database.yml", "#{shared_path}/config/database.yml"
      end
    end
  end
end