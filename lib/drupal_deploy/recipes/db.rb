require 'yaml'
require 'drupal_deploy/database'

db = DrupalDeploy::Database.new self

set :databases_path, [ 'sites/default/settings.php',
                       '~/.drush/database.php', '~/.drush/database.yml', 
                       '/etc/drush/database.php','/etc/drush/database.yml' ]


namespace :drupal do
  namespace :db do
    task :import, :roles => :db_access do
      run "#{drush_bin}" 
    end

    task :update, :roles => :db_access do
    end

    task :rollback, :roles => :db_access do
    end

    # Sources of credentials:
    #  * drush alias (db-user and db-admin)
    #  * cap config (db_user and db_admin)
    #  * yml file db_user and db_admin
    #  * php file $db_user and $db_admin
    #  * settings.php
    #  * array of the above in order of precedence
    task :configure do
      unless variables[:databases].is_a? Hash
        set :databases, {}
      end

      db.configure

      unless databases.nil? || databases.is_a?(Hash)
        throw DrupalDeploy::Error.new "Invalid value for databases: #{databases.inspect}"
      end
      logger.important "Using database settings #{databases.inspect}"
    end

    task :update_settings do
    end
  end

  namespace :version do
    task :create, :roles => :db_access do
    end

    task :rollback, :roles => :db_access do
    end
  end
end
