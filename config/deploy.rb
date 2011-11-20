require 'bundler/capistrano'
set :application, "dreamsunlimited_production"
set(:deploy_to) { "/var/www/dreamsunlimited" }
set :user, 'root'
set :repository, "gaurav-midha/dreamsunlimited.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "173.45.226.90"                          # Your HTTP server, Apache/etc
role :app, "173.45.226.90"                          # This may be the same as your `Web` server
role :db,  "173.45.226.90", :primary => true # This is where Rails migrations will run
role :db,  "173.45.226.90"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
# bundler bootstrap

# tasks
namespace :deploy do

  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  desc "invoke the db migration"
  task:migrate, :roles => :db do
    send(run_method, "cd #{current_path} && rake db:migrate RAILS_ENV=production ")
  end

  desc "create database"
  task:create_db, :roles => :db do
    send(run_method, "cd #{current_path} && rake db:create RAILS_ENV=production ")
  end

  desc "reset database"
  task:reset_db, :roles => :db do
    send(run_method, "cd #{current_path} && rake db:reset RAILS_ENV= ")
  end

  desc "Deploy with migrations"
  task :long do
    transaction do
      update_code
      web.disable
      symlink
      migrate
    end

    restart
    web.enable
    cleanup
  end

  desc "create database"
  task :create do
    transaction do
      update_code
      web.disable
      symlink
      create_db
    end

    restart
    web.enable
    cleanup
  end

  desc "load seed data"
  task :seed, :roles => :db do
    send(run_method, "cd #{current_path} && rake db:seed RAILS_ENV=production ")
  end

  task :after_symlink, :roles => [:app, :db] do
    run "cp #{shared_path}/database.yml #{current_path}/config/database.yml"
    #update_crontab
  end

  desc "Run cleanup after long_deploy"
  task :after_deploy do
    cleanup
  end

  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    run "cd #{current_path} && whenever --update-crontab #{application}"
  end

end
