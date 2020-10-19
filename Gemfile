source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3.4'
gem 'railties', '~> 6', '>= 6.0.3.4'
# gem 'rake', '~> 13.0.1'
# gem 'rake', '~> 12.3.2'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1', '>= 1.1.4'
# Use Puma as the app server
gem 'puma', '~> 3.11.4'
# Use SCSS for stylesheets
gem 'sassc-rails' #, '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', '>= 4.1.12'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 3.5.5'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
# gem 'mini_racer', '~> 0.1.15'

gem 'bundler'

gem 'devise', '~> 4.4', '>= 4.4.3'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'rainbow', '~> 3.0'
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'
gem 'activerecord-session_store'

# Use Capistrano for deployment

gem 'capistrano', '~> 3.11.0'
# gem 'capistrano-rails', group: :development

gem 'ruby-debug-ide'
  gem 'debase'
  gem 'rdebug'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'react_on_rails'
# gem 'react-rails', '~> 2.4.3'
# Use postgresql as the database for Active Record
# gem 'pg', '~> 0.18'
# Use Puma as the app server
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem 'openssl', '~>2.1.1'

gem 'graphql', '~> 1.8', '>= 1.8.13'

# Use Capistrano for deployment
gem 'capistrano-rails', group: :development do
  gem 'dsl', '~> 0.2.3'
  gem 'capistrano', '~> 3.10.1'
  gem 'capistrano-bundler', '~> 1.2.0'
  gem 'cape', '~> 1.8'
  gem 'capistrano-ext', '~> 1.2.1'
  gem 'capistrano_colors', '~> 0.5.5'
  gem 'capistrano-rbenv', '~> 2.1', '>= 2.1.1'
  gem 'capistrano-deploytags', '~> 1.0', '>= 1.0.7'
  # gem 'capistrano-passenger', '~> 0.2.0'
end

gem 'rack-cors', :require => 'rack/cors'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'libv8', '~> 6.3'

gem 'thor','>= 0.14', '< 2.0'

# gem 'postgres_ext', '~> 3.0', '>= 3.0.1'
#gem 'activerecord-postgresql-adapter', '~> 0.0.1'
# gem 'sqlite3-ruby',:require=>'sqlite3'
gem 'sqlite3', '~> 1.3.13'
# gem 'passenger', '~> 5.2.3'

gem 'json', '~> 2.1.0'

# Gems for image handling
gem 'rmagick', '~> 2.16.0'
#gem 'rubysl-fileutils', '~> 2.0.3'
#gem 'fileutils', '~> 0.7'
gem 'streamio-ffmpeg', '~> 3.0.2'

gem 'ffi', '~> 1.13'

gem 'ipaddr', '~> 1.2.2'

gem 'minitest', '~> 5.2'
gem 'activerecord', '~> 6.0.3.4'
gem 'activemodel', '~> 6.0.3.4'
gem 'actionmailer', '~> 6.0.3.4'

gem 'actionpack', '~> 6.0.3.4'
gem 'activestorage', '~> 6.0.3.4'
gem 'activesupport', '~> 6.0.3.4'

gem 'rb-readline', '~> 0.5.3'

gem 'test-unit', '~> 3.2.4'

group :development do
  gem 'rack-mini-profiler' # 簡易プロファイラ
  gem 'annotate' # generate models from definitions in schema.rb
end

gem 'power_assert', '1.0.2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  # gem 'typescript-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'mini_racer', :platforms => :ruby
  gem 'execjs'

  gem 'uglifier', '>= 4.1.12'
  gem 'jquery-rails', '~> 4.3.1'
  gem 'jquery-ui-rails', '~> 6.0', '>= 6.0.1'
end

# Use unicorn as the web server
# gem 'unicorn', '~> 5.3.0'

gem 'ethon', '>= 0.9.0'
gem 'typhoeus'

# Bundle edge Rails instead:
#
gem 'rack-cache', '~> 1.7.0'
gem 'memcachier', '~> 0.0.2'
gem 'dalli', '~> 2.7.6'

# Gems for image handling
gem 'multi_json', '~> 1.2'
#
#
gem 'yaml_db', '~> 0.7.0'

# gem 'commands', '~> 0.2.1'

gem 'i18n'

gem 'sourcerer', '~> 0.7.0'
gem 'rack-proxy', '~> 0.6.3'

gem 'foreman', '~> 0.87.0'

gem 'graphiql-rails', group: :development
