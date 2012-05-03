require 'drush_deploy/paths'

load DrushDeploy::Paths.recipe("setup")

load DrushDeploy::Paths.recipe("general")
load DrushDeploy::Paths.recipe("deploy")
load DrushDeploy::Paths.recipe("drupal")
load DrushDeploy::Paths.recipe("db")
