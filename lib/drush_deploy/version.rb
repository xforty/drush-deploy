require 'logger'

require File.expand_path("../base_version.rb",__FILE__)

module DrushDeploy
  def self.generate_version(logger = Logger.new(nil))
    return VERSION if defined? VERSION
    path = File.expand_path('../../..',__FILE__)
    unless File.exists?(File.expand_path('.git',path))
      logger.error "Couldn't find git repository, falling back to base version"
      return BASE_VERSION
    end

    begin
      require 'git'
    rescue LoadError => e
      e.message.insert 0, "Generating DrushDeploy.generate_version requires 'git' gem.\n"
      raise e
    end
    git = Git.open path
    pre_prefix = false
    needs_build = false
    base = 'develop'
    increment = false
    br = git.current_branch
    if br == 'develop' || br =~ /^feature\//
      increment = true
      needs_build = true
    elsif br =~ /^release\//
      pre_prefix = 'pre'
    elsif br =~ /^hotfix\//
      pre_prefix = 'pre'
      base = 'master'
    elsif br != "master"
      logger.error "Couldn't parse branch '#{br}'! Just using DrushDeploy::BASE_VERSION"
    end

    if git.diff('HEAD', path).size > 0
      logger.info "Working directory is dirty, building 'build' version"
      needs_build = true
    end

    version = BASE_VERSION
    if increment
      version = version.sub(/[^\.]*$/) {|p| p.to_i + 1}
    end

    if pre_prefix
      commits = git.lib.log_commits(:between =>[base,'HEAD']).size
      commits += 1 if needs_build

      version += ".#{pre_prefix}.#{commits}" if commits > 0
    end
    version += ".build."+Time.now.utc.strftime("%Y%m%d%H%M%S") if needs_build

    version
  end

  if Gem.loaded_specs["drush-deploy"]
    VERSION = Gem.loaded_specs["drush-deploy"].version
  else
    VERSION = generate_version
  end
end
