require 'drush_deploy/database'

before "deploy", "drupal:setup_build"
before "deploy:symlink", "drupal:symlink"
after "drupal:symlink", "drupal:check_permissions"
after "deploy", "drupal:clearcache"
before "drupal:install_profile", "db:drupal:configure"

namespace :drupal do
  desc "Symlink shared directories"
  task :symlink, :roles => :web do
    run "mkdir -p #{shared_path}/default/files || true"
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

  desc "Install profile from command line"
  task :install_profile, :roles => :web do
      script= <<-END
        cd '#{latest_release}'
        for p in `ls profiles`
        do
          echo "$(sed -n 's/name[ \t]*=[ \t]*//p' profiles/$p/$p.info) ($p)"
        done
      END
      put script, '/tmp/select_profile.sh'
      profiles = capture('bash /tmp/select_profile.sh').split(/\n/)

      profile = Capistrano::CLI.ui.choose(*profiles) {|m| m.header = "Choose installation profile"}
      machine_name = profile.match(/.*\((.*)\)$/)[1]
      site_name = Capistrano::CLI.ui.ask("Site name?")
      site_email = Capistrano::CLI.ui.ask("Site email?")
      admin_email = Capistrano::CLI.ui.ask("Admin email?")
      admin_user = Capistrano::CLI.ui.ask("Admin username?")
      admin_password = Capistrano::CLI.password_prompt("Admin password?")
      arguments = Capistrano::CLI.password_prompt("Additional profile settings (key=value)?")
      dbconf = databases[:default][:default]
      db_url = DrushDeploy::Database.url(dbconf)

      run "cd '#{latest_release}' && #{drush_bin} site-install --yes --db-url='#{db_url}'"\
          " --account-mail='#{admin_email}' --account-name='#{admin_user}' --account-pass='#{admin_password}'"\
          " --site-name='#{site_name}' --site-mail='#{site_email}' "\
          "#{dbconf[:admin_username] ? "--db-su='#{dbconf[:admin_username]}'" : ''} #{dbconf[:admin_password] ? "--db-su-pw='#{dbconf[:admin_password]}'" : ''}"\
          "#{machine_name} #{arguments}", :once => true
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

  desc "Sync files and sql between drupal sites"
  task :sync, :roles => :web do
    sync_files
    sync_db
  end

  desc "Sync files between drupal sites"
  task :sync_files, :roles => :web do
    unless exists?(:target) && exists?(:source)
      abort "target and source must both be set for syncing"
    end
    run_locally "drush rsync @#{source.sub(/^@/,'')}:%files @#{target.sub(/^@/,'')}:%files --yes"
  end

  desc "Sync database between drupal sites"
  task :sync_db, :roles => :web do
    unless exists?(:target) && exists?(:source)
      abort "target and source must both be set for syncing"
    end
    run_locally "drush sql-sync @#{source.sub(/^@/,'')} @#{target.sub(/^@/,'')} --yes"
    clearcache
  end

end
