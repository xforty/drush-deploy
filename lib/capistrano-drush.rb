require 'railsless-deploy'
require 'drush/capistrano'

configuration = Capistrano::Configuration.instance(:must_exist) 


configuration.load do
  set :deploy_via, :copy
  _cset :drush_bin, "drush"
  _cset :make, nil
  _cset :makefile, 'distro.make'

  # --------------------------------------------
  # Calling our Methods
  # --------------------------------------------
  before "deploy", "drupal:setup_build"
  before "deploy", "drupal:check_permissions"
  after "deploy:symlink", "drupal:symlink"
  after "deploy", "drupal:setup"
  after "deploy", "drupal:clearcache"
  after "deploy", "deploy:cleanup"


  drush_cap = Drush::Capistrano.new
  desc "Show list of valid targets"
  task :targets do
    drush_cap.targets.each {|t| puts t}
  end

  if ENV['TARGET']
    drush_cap.load_target ENV['TARGET']
  end

  # --------------------------------------------
  # Overloaded Methods
  # --------------------------------------------
  namespace :deploy do
    desc "Setup shared application directories and permissions after initial setup"
    task :setup_shared do
      # remove Capistrano specific directories
      run "rm -Rf #{shared_path}/log"
      run "rm -Rf #{shared_path}/pids"
      run "rm -Rf #{shared_path}/system"

      run "[[ -e '#{shared_path}/default/files' ]] || mkdir -p #{shared_path}/default/files"
    end

    namespace :web do
      desc "Disable the application and show a message screen"
      task :disable, :roles => :web do
        run "#{drush_bin} -r #{latest_release} vset --yes site_offline 1"
      end

      desc "Enable the application and remove the message screen"
      task :enable, :roles => :web do
        run "#{drush_bin} -r #{latest_release} vdel --yes site_offline"
      end
    end
  end
  
  # --------------------------------------------
  # Drupal-specific methods
  # --------------------------------------------
  namespace :drupal do
    desc "Symlink shared directories"
    task :symlink, :roles => :web, :except => { :no_release => true } do
      run "ln -nfs #{shared_path}/default/files #{latest_release}/sites/default/files"
    end
   
    desc "Clear all Drupal cache"
    task :clearcache, :roles => :web, :except => { :no_release => true } do
      run "#{drush_bin} -r #{current_path} cache-clear all"
    end
  
    desc "Protect system files"
    task :protect, :roles => :web, :except => { :no_release => true } do
      run "chmod 644 #{latest_release}/sites/default/settings.php"
    end

    desc "Run install or update scripts for Drupal"
    task :setup, :roles => :web, :except => { :no_release => true } do
      1
    end

    task :install_profile, :roles => :web, :except => { :no_release => true } do
        script= <<-END
          PROFILES="$(
            for p in `ls profiles`
            do
              echo "$(sed -n 's/name[ \t]*=[ \t]*//p' profiles/$p/$p.info) ($p)"
            done)"
          IFS=$'\n'
          select PROFILE in $PROFILES; do break; done
          PROFILE="$(echo "$PROFILE" | sed 's/.*(\(.*\))$/\1/'")"
        END
    end

    task :setup_build, :roles => :web, :except => { :no_release => true } do
      if ENV['MAKE']
        set :make, ENV['MAKE'] =~ /^(0|no?)$/i
      end
      if ENV['MAKEFILE']
        set :makefile, ENV['MAKEFILE']
      end

      build_cmd = "drush make '#{makefile}' ."

      if make.nil?
        build_cmd = "[ -f index.php ] || { [ -f '#{makefile}' ] && #{build_cmd}; }"
      end
      if make != false
        set :build_script, build_cmd
      end
    end

    desc "Check and fix if any permissions are set incorrectly."
    task :check_permissions do
      if ! defined? www_user or www_user.nil?
        user = capture(%q{ps -eo user,comm,pid,ppid | awk '$2 ~ /^apache.*|^httpd$/ && $1 != U && $3 != P {P=$4; U=$1} END { print U }'}).strip
        if user
          set :www_user, user
          logger.important "Guessing that #{user} is the www_user, if this is wrong please set www_user manually in config"
        else
          logger.important "Not setting permissions: Unable to determine www_user, please set manually in config"
        end
      end
      if ! defined? www_user or www_user.nil?
        run "setfacl -Rdm u:#{www_user}:rwx #{shared_path}/default/files && setfacl -Rm u:#{www_user}:rwx #{shared_path}/default/files"
      end
    end

  end
end
