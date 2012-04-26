require 'drupal_deploy/capistrano'

set :deploy_via, :copy
set :scm, :none
set :repository, "."
_cset :drush_bin, "drush"
_cset :make, nil
_cset :makefile, 'distro.make'

set :drush, ENV['DRUSH'] if ENV['DRUSH']
set :scm, ENV['SCM'] if ENV['SCM']
set :repository, ENV['REPO'] if ENV['REPO']
set :target, ENV['TARGET'] if ENV['TARGET']
set :source, ENV['SOURCE'] if ENV['SOURCE']

set :databases_path, [ 'sites/default/settings.php',
                       '~/.drush/database.php', '~/.drush/database.yml', 
                       '/etc/drush/database.php','/etc/drush/database.yml' ]
set :databases, {}

set :database_ports, { :pgsql => 5432, :mysql => 3306 }

set :configured, false

set :db_tables_query, %q{SELECT table_name FROM information_schema.tables WHERE table_schema = '%{database}' AND table_type = 'BASE TABLE'};



set :drush_cap, DrupalDeploy::Capistrano.new

if exists? :target
  target.split(/ *, */).each {|t| drush_cap.load_target t }
end
