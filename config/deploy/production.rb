set :stage, :production
# Default branch is :master
set :branch, 'secret_files_rev01'

set :full_app_name, "#{fetch(:application)}_#{fetch(:stage)}"
set :server_name, "117.102.186.81"
# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"
set :deploy_to, "/webapps/spin/#{fetch(:application)}"

# setup rbenv
set :rbenv_type, :system
set :rbenv_ruby, '2.4.4'
set :rbenv_prefix, "env LD_LIBRARY_PATH=/opt/local/lib:/opt/PostgreSQL/9.6/lib:/usr/local/lib RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

set :rails_env, :production

set :archive_options, '--format=tar'

set :linked_files, %w{config/secrets.yml config/database.yml config/routes.rb config/webpacker.yml Gemfile webpack.config.js set_assets_and_start.sh}

set :linked_dirs, %w{bin log config node_modules db tmp/pids tmp/cache tmp/sockets vendor/cache public/system app/assets app/views public/camus_audio_guide}
# set :linked_dirs, %w{bin log config node_modules db tmp/pids tmp/cache tmp/sockets vendor/cache public/system app/assets public/camus_audio_guide}

# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server "example.com", user: "deploy", roles: %w{app db web}, my_property: :my_value
# server "example.com", user: "deploy", roles: %w{app web}, other_property: :other_value
# server "db.example.com", user: "deploy", roles: %w{db}
# server "www.audiokyoto.com", user: "deploy", roles: %w{app db web}, my_property: :my_value


# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}


# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
set :ssh_options, {
    keys: %w(/Users/kazuhiroomachi/.ssh/id_rsa),
    forward_agent: true,
    auth_methods: %w(publickey),
}
#

# The server-based syntax can be used to override options:
# ------------------------------------
# server "example.com",
#   user: "user_name",
#   roles: %w{web app},
#   ssh_options: {
#     user: "user_name", # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: "please use keys"
#   }
server "117.102.186.81", user: "teamdomain", roles: %w{web app db}, primary: true
