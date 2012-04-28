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



set :drush_cap, DrupalDeploy::Capistrano.new

if exists? :target
  target.split(/ *, */).each {|t| drush_cap.load_target t }
end
