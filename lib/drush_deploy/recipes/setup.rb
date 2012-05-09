require 'drush_deploy/capistrano'

true_values = /^(1|y(es)?|t(rue)?)$/i

set :scm, :none
set :repository, "."
set :make, :auto
set :makefile, 'distro.make'
set :databases, {}
set :update_modules, true

set :scm, ENV['SCM'].to_sym if ENV['SCM']
set :repository, ENV['REPO'] if ENV['REPO']
if ENV['MAKE']
  set :make, (ENV['MAKE'] == 'auto' ? :auto : (ENV['MAKE'] =~ true_values))
end
set :makefile, ENV['MAKEFILE'] if ENV['MAKEFILE']
set :update_modules, (ENV['UPDATE_MODULES'] =~ true_values) if ENV['UPDATE_MODULES']

set :target, ENV['TARGET'] if ENV['TARGET']
set :source, ENV['SOURCE'] if ENV['SOURCE']

set :application, 'Drupal'
set :deploy_via, :copy
set :use_sudo, false
set :drush_bin, "drush"

set :databases_path, [ '~/.drush/database.php', '~/.drush/database.yml', 
                       '/etc/drush/database.php','/etc/drush/database.yml',
                       'sites/default/default.settings.php']

set :database_ports, { :pgsql => 5432, :mysql => 3306 }

set :configured, false


set :drush_cap, DrushDeploy::Capistrano.new

if exists? :target
  target.split(/ *, */).each {|t| drush_cap.load_target t }
end
