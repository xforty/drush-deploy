task :default => [:build]

task :build do
  sh "gem build drush-deploy.gemspec"
end

task :rebuild => [:clean, :build]

task :clean do
  sh "rm drush-deploy*.gem"
end
