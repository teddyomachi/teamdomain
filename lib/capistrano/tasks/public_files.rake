# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.1'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

namespace :deploy do
  desc "Upload files under public directory."
  task :public_files do
    public_directories = Dir.glob("public/*")
    on roles(:app) do
      public_directories.each do |public_dir|
        unless test "[ -d #{shared_path}/public ]"
          execute "/bin/mkdir -p #{shared_path}/public"
        end
        puts "#{public_dir}" + " => " + "#{shared_path}/"
        upload! "#{public_dir}", "#{shared_path}/public/", {recursive: true, mkdir: true}
      end
    end
    # on roles(:app) do
    #   %w[public].each do |public_dir|
    #     unless test "[ -d #{shared_path}/#{public_dir} ]"
    #       execute "/bin/mkdir -p #{shared_path}/#{public_dir}/"
    #     end
    #     puts "#{public_dir}" + " => " + "#{shared_path}/"
    #     upload! "#{public_dir}", "#{shared_path}/", recursive: true
    #   end
    # end
  end
end