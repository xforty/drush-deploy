$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'drush_deploy/version'

Gem::Specification.new do |s|
  s.name        = 'drush-deploy'
  s.version     = DrushDeploy::generate_version(logger: Logger.new(STDERR), use_build: ENV['USE_BUILD'])
  s.summary     = "Deployment strategy for Drupal using Drush"
  s.description = "Utilizes capistrano to allow for doing intellegent deployments of drupal projects."
  s.authors     = ["Matt Edlefsen"]
  s.email       = 'matt@xforty.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/xforty/drush-deploy'
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
    "README.md"
  ]

  s.add_runtime_dependency(%q<capistrano>, [">=2.12"])
  s.add_runtime_dependency(%q<railsless-deploy>, [">=1.0.2"])
end
