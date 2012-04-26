require 'yaml'
require 'drupal_deploy/database'

drupal_db = DrupalDeploy::Database.new(self)

settings_attrs = %w(driver database username password host port prefix collation).map &:to_sym

namespace :drupal do
  namespace :db do
    task :import, :roles => :db_access do
      run "#{drush_bin}" 
    end

    task :update, :roles => :db_access do
    end


    task :configure do
      return if configured
      drupal_db.configure

      unless databases.nil? || databases.is_a?(Hash)
        throw DrupalDeploy::Error.new "Invalid value for databases: #{databases.inspect}"
      end

      # Set some defaults
      DrupalDeploy::Database.each_db(databases) do |db|
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

    task :update_settings do
      configure unless configured
      settings = databases.inject({}) do |h,(k,site)|
        h[k] = site.inject({}) do |h,(k,db)|
          h[k] = db.keep_if { |k,v| DrupalDeploy::Database::STANDARD_KEYS.include? k }
          h
        end
        h
      end
      drupal_db.update_settings(settings)
    end
  end

  before "drupal:version:create", "drupal:db:configure"
  before "drupal:version:rollback", "drupal:db:configure"
  namespace :version do
    task :create, :roles => :db_access do
      unless releases.empty?
        current = drupal_db.config[:database]
        backup = "#{current}_#{releases.last}"
        unless drupal_db.db_exists? backup
          on_rollback do
            drupal_db.drop_database backup
          end
          drupal_db.copy_database(current,backup)
        end
      end
    end

    task :rollback, :roles => :db_access do
      unless releases.size > 1
        throw DrupalDeploy::Error.new "No previous versions to rollback to"
      end
      current = drupal_db.config[:database]
      release = releases.last
      source = "#{current}_#{releases[-2]}"
      backup = "#{current}_backup"
      if drupal_db.db_exists? source
        drupal_db.rename_database(current,backup)
        drupal_db.rename_database(source,current)
        drupal_db.drop_database(backup)
      end
    end
  end
end
