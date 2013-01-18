drush-deploy
============
version 1.0.12 - [changelog](https://github.com/xforty/drush-deploy/wiki/CHANGELOG)

Provides capistrano deployment strategy for Drupal by using Drush.

### Local Requirements

* Ruby
* Drush

### Remote Requirements

* Drush
* File system acls enabled (`setfacl`)

### Basic Usage

        # Initial Setup
        gem install drush-deploy

        # Once for each new site
        drush-deploy TARGET=<drush alias> deploy:setup
           
        # To deploy
        cd <Drupal root>
        drush-deploy TARGET=<drush alias>

### Resources

* [Project Wiki](https://github.com/xforty/drush-deploy/wiki) - HowTos,
  FAQs, and advanced usage
* [Project Issues](https://github.com/xforty/drush-deploy/issues) - submit
  bugs, support questions, and feature requests
* [Development](https://github.com/xforty/drush-deploy/wiki/Development)
* [Drush Documentation](http://drush.ws)
* [Capistrano Documentation](https://github.com/capistrano/capistrano/wiki)
* [Railsless-Deploy Documentation](https://github.com/leehambley/railsless-deploy/)

---------------------------------------------------------------------
Maintained by [xforty technologies](http://www.xforty.com)
