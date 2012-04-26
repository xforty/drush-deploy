version 0.1.0

## DESCRIPTION

Provides capistrano deployment strategy for Drupal Drush Makefiles.  Initial
this gem is build on top of capistrano-ash.  Further development will likely
require ditching this requirement.

## REQUIREMENTS

* Capistrano 
* Capistrano-ext
* railsless-deloy
* capistrano-ash

## USAGE

        # gem install capistrano-drush-make

## Capfile

* set :deploy_via, :drush_make
* set :strategy, Capistrano::Deploy::Strategy::DrushMake.new(self)

* set :default_multisite, "multisite_directory_to_link_default_to"


## TODO

* Rebuild to eliminate capistrano-ash tasks.
* Work on a deployment that goes to default and ignores multisite
