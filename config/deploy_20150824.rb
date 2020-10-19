require 'bundler/capistrano'
require "rvm/capistrano"

set :rvm_ruby_string, :local              # use the same ruby as used locally for deployment

before 'deploy', 'rvm:install_rvm'  # install RVM
before 'deploy', 'rvm:install_ruby' # install Ruby and create gemset, OR:
# by teddy
before "deploy:update" do
#  run "/usr/bin/rsync -au /usr2/teamdomain/spinvfs/root1_thumbnail/* /usr2/teamdomain/thumbnail_backup/"
end

set :application, "secret_files"
set :rails_env, 'production'
set :keep_releases, 2

# user should set SPIN_HOST environmental variable
case ENV['SPIN_HOST']
when 'jupiter'
  set :default_environment, {
    'PATH' => "/home/spinshare/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => '2.1.2',
    'GEM_HOME'     => '/home/spinshare/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/spinshare/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/spinshare/.rvm/gems/ruby-2.1.2'  # If you are using bundler.
  }
  server '210.196.120.219', :web, :app, :db, :primary => true
#  server 'jupiter.timefactorinc.com', :web, :app, :db, :primary => true
  set :user, 'spinshare'
when 'jupiter-local'
  set :default_environment, {
    'PATH' => "/home/spinshare/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => '2.1.2',
    'GEM_HOME'     => '/home/spinshare/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/spinshare/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/spinshare/.rvm/gems/ruby-2.1.2'  # If you are using bundler.
  }
  server '192.168.0.9', :web, :app, :db, :primary => true
#  server 'jupiter.timefactorinc.com', :web, :app, :db, :primary => true
  set :user, 'spinshare'
when 'venus'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => '2.1.2',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.2'  # If you are using bundler.
  }
  server 'venus.timefactorinc.com', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'mercure'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => '2.1.2',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.2'  # If you are using bundler.
  }
  server '203.141.101.247', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'mercure-local'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => 'ruby-2.1.2',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.2',  # If you are using bundler.
    'LD_LIBRARY_PATH' => '/usr/local/lib:$LD_LIBRARY_PATH'
  }
  server 'mercure.timefactorinc.com', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'mercure-teddy'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => 'ruby-2.1.2',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.2',  # If you are using bundler.
    'LD_LIBRARY_PATH' => '/usr/local/lib:$LD_LIBRARY_PATH'
  }
  server '192.168.2.7', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'saturne'
  set :default_environment, {
    'PATH' => "/Users/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => '2.1.2',
    'GEM_HOME'     => '/Users/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/Users/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/Users/teamdomain/.rvm/gems/ruby-2.1.2'  # If you are using bundler.
  }
  server 'saturne.timefactorinc.com', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'saturne-local'
  set :default_environment, {
    'PATH' => "/Users/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => '2.1.2',
    'GEM_HOME'     => '/Users/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/Users/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/Users/teamdomain/.rvm/gems/ruby-2.1.2'  # If you are using bundler.
  }
  server '192.168.0.10', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'venus-note'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.4/bin:$PATH",
    'RUBY_VERSION' => '2.1.4',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.4',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.4',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.4'  # If you are using bundler.
  }
#  server '192.168.63.129', :web, :app, :db, :primary => true
  server '192.168.100.106', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'venus-local'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.4/bin:$PATH",
    'RUBY_VERSION' => '2.1.4',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.4',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.4',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.4'  # If you are using bundler.
  }
  server '192.168.10.111', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'uranus'
  set :default_environment, {
    'PATH' => "/home/spinshare/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => '2.1.2',
    'GEM_HOME'     => '/home/spinshare/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/spinshare/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/spinshare/.rvm/gems/ruby-2.1.2'  # If you are using bundler.
  }
  server 'uranus.timefactorinc.com', :web, :app, :db, :primary => true
  set :user, 'spinshare'
when 'dione'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => 'ruby-2.1.2',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.2',  # If you are using bundler.
    'LD_LIBRARY_PATH' => '/usr/local/lib:$LD_LIBRARY_PATH'
  }
  server '192.168.0.160', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'boombox1'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => 'ruby-2.1.2',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.2',  # If you are using bundler.
    'LD_LIBRARY_PATH' => '/usr/local/lib:$LD_LIBRARY_PATH'
  }
  server '192.168.0.161', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
when 'boombox2'
  set :default_environment, {
    'PATH' => "/home/teamdomain/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => 'ruby-2.1.2',
    'GEM_HOME'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/teamdomain/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/teamdomain/.rvm/gems/ruby-2.1.2',  # If you are using bundler.
    'LD_LIBRARY_PATH' => '/usr/local/lib:$LD_LIBRARY_PATH'
  }
  server '192.168.0.162', :web, :app, :db, :primary => true
  set :user, 'teamdomain'  
else
  set :default_environment, {
    'PATH' => "/home/spinshare/.rvm/rubies/ruby-2.1.2/bin:$PATH",
    'RUBY_VERSION' => '2.1.2',
    'GEM_HOME'     => '/home/spinshare/.rvm/gems/ruby-2.1.2',
    'GEM_PATH'     => '/home/spinshare/.rvm/gems/ruby-2.1.2',
    'BUNDLE_PATH'  => '/home/spinshare/.rvm/gems/ruby-2.1.2'  # If you are using bundler.
  }
  server 'mercure.timefactorinc.com', :web, :app, :db, :primary => true
  set :user, 'teamdomain'
end
#server 'mercure.timefactorinc.com', :web, :app, :db, :primary => true
#server 'venus.timefactorinc.com', :web, :app, :db, :primary => true
#server 'jupiter.timefactorinc.com', :web, :app, :db, :primary => true
#server '192.168.2.111', :web, :app, :db, :primary => true

set :repository,  "git@github.com:teddyomachi/spincella.git"
set :scm, :git # You can set :scm explicitly or Capistrano will make an dintelligent guess based on known version control directory names
#set :branch, 'rc1'
set :branch, 'boombox_R120_rev22'
#set :user, 'spinshare'
#set :user, 'teamdomain'
set :use_sudo, false

set :deploy_to, "/webapps/spin/secret_files"
set :deploy_via, :remote_cache

#deploy_host = ENV["HOSTNAME"].split(/-/)[0]

ssh_options[:forward_agent] = true
#ssh_options[File.join(ENV["HOME"],".ssh","id_mercure_rsa")]

#role :web, '192.168.2.111','venus.timefactorinc.com'        # Your HTTP server, Apache/etc
#role :app, '192.168.2.111','venus.timefactorinc.com'        # This may be the same as your `Web` server
#role :db,  '192.168.2.111', :primary => true                            # This is where Rails migrations will run
#role :db,  'venus.timefactorinc.com'

# if you want to clean up old releases on each deploy uncomment this:
 after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  desc "Restart your application."
  task :restart do
    run "mkdir -p #{shared_path}/tmp"
    run "touch #{shared_path}/tmp/restart.txt"
  end
end

after "deploy:update", :roles => :app do
  run "/bin/cp #{shared_path}/config/database.yml #{release_path}/config/"
#  run "/usr/bin/rsync -au /usr2/teamdomain/thumbnail_backup/* /usr2/teamdomain/spinvfs/root1_thumbnail/"
end
