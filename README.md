version 1.0.6

## DESCRIPTION

Provides capistrano deployment strategy for Drupal.

For documentation please checkout the [wiki](https://github.com/xforty/drush-deploy/wiki)

## REQUIREMENTS

* Capistrano 
* railsless-deloy
* php\_serialize
* Drush

On remote servers you must have

* Drush
* File system acls enabled (`setfacl`)

## USAGE

        # Initial Setup
        gem install drush-deploy

        # Once for each new site
        drush-deploy TARGET=<drush alias> deploy:setup
           
        # To deploy
        cd <Drupal root>
        drush-deploy TARGET=<drush alias>
