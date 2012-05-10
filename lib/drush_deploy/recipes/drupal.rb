require 'drush_deploy/database'

before "deploy", "drupal:setup_build"
before "deploy:symlink", "drupal:symlink"
after "drupal:setup", "drupal:check_permissions"
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
    unless drupal_db.db_empty?
      run "#{drush_bin} -r #{latest_release} cache-clear all"
    end
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
    build_cmd = "drush make #{make_args} '#{makefile}' ."

    if make == :auto
      build_cmd = "[ -f index.php ] || { [ -f '#{makefile}' ] && #{build_cmd}; }"
    end
    if make
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
      run "which setfacl &>/dev/null && setfacl -Rdm u:#{www_user}:rwx #{shared_path}/default/files && setfacl -Rm u:#{www_user}:rwx #{shared_path}/default/files"
    end
  end

end
