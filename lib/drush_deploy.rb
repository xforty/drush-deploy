require 'railsless-deploy'
require 'drush_deploy/paths'

class Capistrano::Configuration
  alias_method :filter_deprecated_tasks_without_drush_deploy, :filter_deprecated_tasks
  def filter_deprecated_tasks_with_drush_deploy(names)
    if names == "deploy:symlink"
      names
    elsif names.is_a?(Array)
      filter_deprecated_tasks_without_drush_deploy (names.reject {|n| n == "deploy:symlink"})
    else
      filter_deprecated_tasks_without_drush_deploy names
    end
  end
  alias_method :filter_deprecated_tasks, :filter_deprecated_tasks_with_drush_deploy
end

Capistrano::Configuration.instance(:must_exist).load DrushDeploy::Paths.recipe('all')

