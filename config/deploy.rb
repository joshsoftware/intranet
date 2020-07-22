require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
#require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)
require 'mina_extensions/sidekiq'

#Basic settings:
#domain       - The hostname to SSH to.
#deploy_to    - Path to deploy into.
#repository   - Git repo to clone from. (needed by mina/git)
#branch       - Branch name to deploy. (needed by mina/git)

env = ENV['on'] || 'staging'
nocron = ENV['nocron'] || false
branch = ENV['branch'] || 'master'
#bkp = ENV['bkp'] || false #Backup will be used for actual production
index = ENV['index'] || false

if env == 'production'
  ip = '139.59.30.77'
  set :deploy_to, "/home/deploy/projects/intranet"
  #branch = 'develop' # Always production!!
elsif env == 'staging'
  #staging
  #ip = '74.207.241.229'
  ip = '139.59.30.77'
  set :deploy_to, "/home/deploy/staging/intranet"
  nocron = true
  branch = ENV['branch'] || 'staging'
end
set :term_mode, nil
set :domain, ip
set :user, 'deploy'
#set :identity_file, "#{ENV['HOME']}/.ssh/id_joshsite_rsa"

set :repository, 'git@github.com:joshsoftware/intranet.git'
set :branch, branch
set :rails_env, env

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/mongoid.yml', 'log', 'tmp', 'public/system', '.env',
					'public/uploads', 'config/initializers/secret_token.rb', "config/initializers/smtp_gmail.rb", "db/seeds.rb",
          "config/initializers/constants.rb", "config/rnotifier.yaml", "config/environment.yml", 'config/service_account_key.p12',
          'config/initializer/rollbar.rb']

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use[2.2.4]'

end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config/initializers"]
  queue! %[chmod -R g+rx,u+rwx "#{deploy_to}/shared/config"]
  queue! %[touch "#{deploy_to}/shared/config/initializers/secret_token.rb"]

  queue! %[touch "#{deploy_to}/shared/config/initializers/smtp_gmail.rb"]
  queue! %[touch "#{deploy_to}/shared/config/initializers/constants.rb"]

  queue! %[touch "#{deploy_to}/shared/config/mongoid.yml"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config/mongoid.yml"]

  queue! %[touch "#{deploy_to}/shared/config/rnotifier.yaml"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config/rnotifier.yaml"]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp"]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids"]

  queue! %[mkdir -p "#{deploy_to}/shared/public/system"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/system"]

  queue! %[mkdir -p "#{deploy_to}/shared/public/uploads"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/uploads"]

  queue! %[mkdir -p "#{deploy_to}/shared/pids/"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/pids"]

  queue! %[mkdir -p "#{deploy_to}/shared/db/"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/db/"]
  queue! %[touch g+rx,u+rwx "#{deploy_to}/shared/db/seeds.rb"]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do

      # Index if required
      if index
        queue "cd #{deploy_to}/current && bundle exec rake db:mongoid:create_indexes RAILS_ENV=#{env}"
      end

      # Update whenever
      unless nocron
        queue "cd #{deploy_to}/current && bundle exec whenever -i intranet_whenever_tasks --update-crontab --set 'environment=#{env}'"
      end
      queue "echo '#{settings.branch}' > #{deploy_to}/#{settings.current_path}/branch_deployed.txt"
      queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
      if env == 'production'
        queue "sudo monit restart sidekiq"
      elsif env == 'staging'
        queue "sudo monit restart sidekiq_staging"
      end
    end
  end
end

