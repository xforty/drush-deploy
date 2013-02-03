require 'logger'

require File.expand_path("../base_version.rb",__FILE__)

module DrushDeploy
  def self.generate_version(opts = {})
    logger = opts[:logger] || Logger.new(nil)
    use_build = opts.key?(:use_build) ? opts[:use_build] : false

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
      needs_build = true
      increment = true
    elsif br =~ /^release\//
      pre_prefix = 'pre'
    elsif br =~ /^hotfix\//
      pre_prefix = 'pre'
      base = 'master'
    elsif br == "master"
      increment = true
    else
      logger.error "Couldn't parse branch '#{br}'! Just using DrushDeploy::BASE_VERSION"
    end

    if git.diff('HEAD', path).size > 0
      logger.info "Working directory is dirty, building dev version"
      needs_build = true
    end

    version = BASE_VERSION
    if increment && needs_build
      version = version.sub(/[^\.]*$/) {|p| p.to_i + 1}
    end

    if pre_prefix
      commits = git.lib.log_commits(:between =>[base,'HEAD']).size
      commits += 1 if needs_build

      version += ".#{pre_prefix}.#{commits}" if commits > 0
    end

    if needs_build
      if use_build
        version += ".dev."+Time.now.utc.strftime("%Y%m%d%H%M%S")
      else
        version += ".dev"
      end
    end

    version
  end

  if Gem.loaded_specs["drush-deploy"]
    VERSION = Gem.loaded_specs["drush-deploy"].version
  else
    VERSION = generate_version
  end
end
