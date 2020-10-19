# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.4'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

# namespace :deploy do
#   desc "Upload files under node_modules directory."
#   task :app_assets do
#     direntries = Dir.glob("app/assets/*")
#     # direntries = Dir.open("app/assets")
#     on roles(:app) do
#       direntries.each do |assets_dir|
#         # unless !(assets_dir == '.' or assets_dir == '..')
#         unless test "[ -d #{shared_path}/app/assets/#{assets_dir} ]"
#           execute "/bin/mkdir -p #{shared_path}/app/assets/#{assets_dir}/"
#         end
#         puts "#{assets_dir}" + " => " + "#{shared_path}/app/assets/"
#         upload! "#{assets_dir}", "#{shared_path}/app/assets/", recursive: true
#         # end
#       end
#       upload! "set_assets_and_start.sh", "#{shared_path}/"
#     end
#   end
# end

namespace :deploy do
  desc "Upload files under node_modules directory."
  task :app_assets do
    direntries = Dir.glob("app/assets/*")
    vdirentries = Dir.glob("app/views/*")
    on roles(:app) do
      direntries.each do |assets_dir|
        # unless !(assets_dir == '.' or assets_dir == '..')
        unless test "[ -d #{shared_path}/app/assets/#{assets_dir} ]"
          execute "/bin/mkdir -p #{shared_path}/app/assets/#{assets_dir}/"
        end
        puts "#{assets_dir}" + " => " + "#{shared_path}/app/assets/"
        upload! "#{assets_dir}", "#{shared_path}/app/assets/", recursive: true
        # end
      end
      vdirentries.each do |views_dir|
        # unless !(assets_dir == '.' or assets_dir == '..')
        unless test "[ -d #{shared_path}/app/views/#{views_dir} ]"
          execute "/bin/mkdir -p #{shared_path}/app/views/#{views_dir}/"
        end
        puts "#{views_dir}" + " => " + "#{shared_path}/app/views/"
        upload! "#{views_dir}", "#{shared_path}/app/views/", recursive: true
        # end
      end
    end
  end
end