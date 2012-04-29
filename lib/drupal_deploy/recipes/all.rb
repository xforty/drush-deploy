require 'drupal_deploy/paths'

load DrupalDeploy::Paths.recipe("setup")

load DrupalDeploy::Paths.recipe("general")
load DrupalDeploy::Paths.recipe("deploy")
load DrupalDeploy::Paths.recipe("drupal")
