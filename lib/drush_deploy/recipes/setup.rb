require 'drush_deploy/capistrano'

set :deploy_via, :copy
set :scm, :none
set :repository, "."
set :drush_bin, "drush"
set :make, nil
set :makefile, 'distro.make'

set :drush, ENV['DRUSH'] if ENV['DRUSH']
set :scm, ENV['SCM'] if ENV['SCM']
set :repository, ENV['REPO'] if ENV['REPO']
set :target, ENV['TARGET'] if ENV['TARGET']
set :source, ENV['SOURCE'] if ENV['SOURCE']

set :databases_path, [ '~/.drush/database.php', '~/.drush/database.yml', 
                       '/etc/drush/database.php','/etc/drush/database.yml',
                       'sites/default/default.settings.php', 'sites/default/settings.php']
set :databases, {}

set :database_ports, { :pgsql => 5432, :mysql => 3306 }

set :configured, false

set :update_modules, true

set :drush_cap, DrushDeploy::Capistrano.new

if exists? :target
  target.split(/ *, */).each {|t| drush_cap.load_target t }
end
