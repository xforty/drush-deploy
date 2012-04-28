require 'railsless-deploy'
require 'drupal_deploy/paths'

Capistrano::Configuration.instance(:must_exist).load DrupalDeploy::Paths.recipe('all')
