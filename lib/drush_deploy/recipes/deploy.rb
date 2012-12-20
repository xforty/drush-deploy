after "deploy", "deploy:cleanup"
before "deploy:cleanup", "deploy:web:fix_sites_default"

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
      run "#{remote_drush} -r #{latest_release} vset --yes site_offline 1"
    end

    desc "Enable the application and remove the message screen"
    task :enable, :roles => :web do
      run "#{remote_drush} -r #{latest_release} vdel --yes site_offline"
    end
    
    desc "Set sites/default directory to writeable for cleanup"
	task :fix_sites_default, :except => { :no_release => true } do
	  count = fetch(:keep_releases, 5).to_i
	  local_releases = capture("ls -xt #{releases_path}").split.reverse
	  if count >= local_releases.length
	    logger.important "no old releases to fix"
	  else
		directories = (local_releases - local_releases.last(count)).map { |release|
		File.join(releases_path, release) }.join(" ")
		  run "chmod -R u+w #{directories}"
	  end
	end
  end
end
