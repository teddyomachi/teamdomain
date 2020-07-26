
# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.1'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

namespace :deploy do
  desc "Upload files under public directory."
  task :vendor_files do
    on roles(:app) do
      %w[vendor].each do |upload_dir|
        unless test "[ -d #{shared_path}/#{upload_dir} ]"
          execute "/bin/mkdir -p #{shared_path}/#{upload_dir}/"
        else
          execute "/bin/rm -Rf #{shared_path}/#{upload_dir}/*"
        end
        puts "#{upload_dir}" + " => " + "#{shared_path}/"
        upload! "#{upload_dir}", "#{shared_path}/", recursive: true
      end
    end
  end
end