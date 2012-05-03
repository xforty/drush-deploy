after "deploy", "deploy:cleanup"

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
