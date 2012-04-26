Gem::Specification.new do |s|
  s.name        = 'capistrano-drush'
  s.version     = '0.1.1'
  s.summary     = "Deployment strategy for Drupal using Drush"
  s.description = "Utilizes capistrano to allow for doing intellegent deployments of drupal projects."
  s.authors     = ["Matt Edlefsen"]
  s.email       = 'matt@xforty.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/medlefsen/capistrano-drush'
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
    "README.md"
  ]

  s.add_runtime_dependency(%q<capistrano>, [">=2.0"])
  s.add_runtime_dependency(%q<railsless-deploy>, [">=1.0.2"])
  s.add_runtime_dependency(%q<php_serialize>, [">=1.2"])
end
