source 'http://rubygems.org'
ruby "2.0.0"
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.0'
gem 'devise'
gem 'mongoid', github: 'mongoid/mongoid'
gem 'mongoid_slug'
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'rmagick'
gem 'mongoid-grid_fs', github: 'ahoward/mongoid-grid_fs'
gem 'twitter-bootstrap-rails'
gem 'haml-rails'
gem 'cancan'
gem 'bson_ext'
gem 'sass-rails', '~> 4.0.0'
gem 'kaminari'
gem 'simple_form', :git => 'git://github.com/plataformatec/simple_form.git'
gem 'nested_form'
gem "omniauth-google-oauth2"
gem 'rnotifier'
gem 'bootstrap-datepicker-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

#mongoid-history
gem 'mongoid-history', github: 'aq1018/mongoid-history'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
gem 'jquery-turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :test do
  gem 'rspec-rails'
  gem 'mongoid-rspec'
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'database_cleaner'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'brakeman', :require => false
end

group :production do
  gem 'therubyracer'
end

gem 'simplecov', :require => false, :group => :test

#BackGround Job processing instead of delayed_job
gem 'sidekiq'
gem 'whenever'
#gem for deploying to remote server
gem 'mina', github: 'nadarei/mina'
gem 'mina_extensions', github: 'marcosbeirigo/mina_extensions'
#gem 'rescue'


# Use ActiveModel has_secure_password


# gem 'bcrypt-ruby', '~> 3.0.0'

#webserver for staging, production
gem 'unicorn'
gem 'thin'

gem 'google-api-client'
gem 'authority'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]
