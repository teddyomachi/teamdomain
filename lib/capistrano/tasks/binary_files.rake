# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.1'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

namespace :deploy do
  desc "Upload files under shared/bin directory."
  task :binary_files do
    on roles(:app) do
      %w[bin].each do |binary_dir|
        unless test "[ -d #{shared_path}/#{binary_dir} ]"
          execute "/bin/mkdir -p #{shared_path}/#{binary_dir}/"
        end
        upload_files = Rake::FileList["#{binary_dir}/*"]
        upload_files.each do |upload_file|
          puts "#{upload_file}" + " => " + "#{shared_path}/#{upload_file}"
          upload! "#{upload_file}", "#{shared_path}/#{upload_file}", recursive: true
        end
      end
    end
  end
end