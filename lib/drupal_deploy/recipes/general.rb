
desc "Show list of valid targets"
task :targets do
  drush_cap.targets.each {|t| puts t}
end
