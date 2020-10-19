# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.1'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

namespace :deploy do
  desc "Upload files under shared/config directory."
  task :config_files do
    on roles(:app) do
      %w[config].each do |config_dir|
        unless test "[ -d #{shared_path}/#{config_dir} ]"
          execute "/bin/mkdir -p #{shared_path}/#{config_dir}/"
        else
          execute "/bin/rm -Rf #{shared_path}/#{config_dir}/*"
        end
        upload_files = Rake::FileList["Rakefile", "Gemfile", "Gemfile.lock", "_Gemfile", "_Gemfile.lock", "webpack.config.js", "yarn.lock"]
        upload_files.each do |upload_file|
          puts "#{upload_file}" + " => " + "#{shared_path}/#{upload_file}"
          upload! "#{upload_file}", "#{shared_path}/#{upload_file}"
        end
        upload_dirs = Rake::FileList["config"]
        upload_dirs.each do |upload_dir|
          puts "#{upload_dir}" + " => " + "#{shared_path}/#{upload_dir}"
          upload! "#{upload_dir}", "#{shared_path}/", recursive: true
        end
      end
    end
  end
end