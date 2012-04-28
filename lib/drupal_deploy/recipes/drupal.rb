before "deploy", "drupal:setup_build"
before "deploy", "drupal:check_permissions"
after "deploy:symlink", "drupal:symlink"
after "deploy", "drupal:setup"
after "deploy", "drupal:clearcache"

namespace :drupal do
  desc "Symlink shared directories"
  task :symlink, :roles => :web do
    run "ln -nfs #{shared_path}/default/files #{latest_release}/sites/default/files"
  end
 
  desc "Clear all Drupal cache"
  task :clearcache, :roles => :web do
    run "#{drush_bin} -r #{current_path} cache-clear all"
  end

  desc "Protect system files"
  task :protect, :roles => :web do
    run "chmod 644 #{latest_release}/sites/default/settings.php"
  end

  desc "Run install or update scripts for Drupal"
  task :setup, :roles => :web do
    1
  end

  task :install_profile, :roles => :web do
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

  task :setup_build, :roles => :web do
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
  task :check_permissions, :roles => :web do
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
