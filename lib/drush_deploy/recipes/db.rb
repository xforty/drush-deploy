require 'drush_deploy/database'


after "deploy:update_code", "db:drupal:update_settings"

if version_database
  after "deploy:update_code", "db:version:create"
  before "deploy:rollback", "db:version:rollback"
end

before "db:version:create", "db:drupal:configure"
before "db:version:rollback", "db:drupal:configure"
before "db:version:cleanup", "db:drupal:configure"

if update_modules
  after "drupal:clearcache", "db:drupal:update"
end
after "deploy:cleanup", "db:version:cleanup"

namespace :db do
  namespace :drupal do
    desc "Run update scripts for Drupal"
    task :update, :roles => :web do
      unless drupal_db.db_empty?
        drupal_db.updatedb
      end
    end

    desc "Determine database settings"
    task :configure do
      unless configured
        drupal_db.configure

        unless databases.nil? || databases.is_a?(Hash)
          throw DrushDeploy::Error.new "Invalid value for databases: #{databases.inspect}"
        end

        # Set some defaults
        DrushDeploy::Database.each_db(databases) do |db|
          if db[:driver]
            db[:driver] = db[:driver].to_sym
          else
            db[:driver] = db[:port] == database_ports[:pgsql] ? :pgsql : :mysql
          end
          db[:host] ||= 'localhost'
          db[:port] ||= database_ports[db[:driver]]
          db[:prefix] ||= ''
          db[:collation] ||= 'utf8_general_ci'
        end
        set :configured, true

        logger.important "Using database settings #{databases.inspect}"
      end
    end

    desc "Update settings.php with database settings"
    task :update_settings do
      configure unless configured
      settings = databases.inject({}) do |h,(k,site)|
        h[k] = site.inject({}) do |h,(k,db)|
          h[k] = db.dup.keep_if { |k,v| DrushDeploy::Database::STANDARD_KEYS.include? k }
          h
        end
        h
      end
      drupal_db.update_settings(settings)
    end
  end

  namespace :version do
    desc "Create a versioned backup of the database"
    task :create, :roles => :web do
      if releases.size > 1
        versioned_databases.each do |conf_name|
          current = drupal_db.config(conf_name)[:database]
          backup = "#{current}_#{releases[-2]}"
          unless drupal_db.db_empty?(current,conf_name) or drupal_db.db_exists? backup,conf_name
            on_rollback do
              drupal_db.drop_database backup, conf_name
            end
            logger.info "Creating backup version of #{conf_name} database as #{backup}"
            drupal_db.copy_database(current,backup,conf_name)
          end
        end
      end
    end

    desc "Rollback to a previous version of the database"
    task :rollback, :roles => :web do
      unless releases.size > 1
        throw DrushDeploy::Error.new "No previous versions to rollback to"
      end
      versioned_databases.each do |conf_name|
        current = drupal_db.config(conf_name)[:database]
        release = releases.last
        source = "#{current}_#{releases[-2]}"
        backup = "#{current}_backup"
        if drupal_db.db_exists? source,conf_name
          logger.info "Rolling back #{conf_name} database to #{source}"
          drupal_db.rename_database(current,backup,conf_name)
          drupal_db.rename_database(source,current,conf_name)
          drupal_db.drop_database(backup,conf_name)
        end
      end
    end

    desc "Cleanup old versions of the database"
    task :cleanup, :roles => :web do
      # Subtract one because the latest release won't be counted
      count = fetch(:keep_releases, 5).to_i - 1
      versioned_databases.each do |conf_name|
        logger.info "Cleaning up #{conf_name} database"
        drupal_db.db_versions(nil,conf_name).drop(count).each do |db|
          drupal_db.drop_database(db,conf_name)
        end
      end
    end
  end
end
