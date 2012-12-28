require 'drush_deploy/capistrano'
require 'drush_deploy/database'

true_values = /^(1|y(es)?|t(rue)?)$/i

set :scm, :none
set :repository, "."
set :make, :auto
set :makefile, 'distro.make'
set :make_args, ''
set :databases, {}
set :update_modules, true
set :version_database, true

set :scm, ENV['SCM'].to_sym if ENV['SCM']
set :repository, ENV['REPO'] if ENV['REPO']
if ENV['MAKE']
  set :make, (ENV['MAKE'] == 'auto' ? :auto : (ENV['MAKE'] =~ true_values))
end
set :makefile, ENV['MAKEFILE'] if ENV['MAKEFILE']
set :make_args, ENV['MAKE_ARGS'] if ENV['MAKE_ARGS']
set :update_modules, (ENV['UPDATE_MODULES'] =~ true_values) if ENV['UPDATE_MODULES']
set :version_database, (ENV['VERSION_DATABASE'] =~ true_values) if ENV['VERSION_DATABASE']

set :target, ENV['TARGET'] if ENV['TARGET']
set :source, ENV['SOURCE'] if ENV['SOURCE']

set :application, 'Drupal'
set :deploy_via, :copy
set :use_sudo, false
set :drush, "drush"
set :remote_drush, "drush"

set(:databases_path) { [ "#{deploy_to}/database.php", "#{deploy_to}/database.yml",
                       '~/.drush/database.php', '~/.drush/database.yml', 
                       '/etc/drush/database.php','/etc/drush/database.yml',
                       'sites/default/default.settings.php'] }

set :database_ports, { :pgsql => 5432, :mysql => 3306 }

set :configured, false


set(:drush_cap) { DrushDeploy::Capistrano.new(self)}
set(:drupal_db) { DrushDeploy::Database.new(self)}
set :versioned_databases, [:default]
set(:targets) { drush_cap.targets }
