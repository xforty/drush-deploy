require 'railsless-deploy'
require 'drush_deploy/paths'

Capistrano::Configuration.instance(:must_exist).load DrushDeploy::Paths.recipe('all')
