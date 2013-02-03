require 'logger'
module DrushDeploy
  VERSION = '1.1.0'

  def self.gem_version(logger = Logger.new(nil))
    begin
      require 'git'
    rescue LoadError => e
      e.message.insert 0, "Generating DrushDeploy.gem_version requires 'git' gem.\n"
      raise e
    end
    path = File.expand_path('../../..',__FILE__)
    git = Git.open path
    pre_prefix = false
    needs_build = false
    base = 'develop'
    br = git.current_branch
    if br == 'develop'
      needs_buid = true
    elsif br =~ /^feature\//
      pre_prefix = 'dev'
    elsif br =~ /^release\//
      pre_prefix = 'pre'
    elsif br =~ /^hotfix\//
      pre_prefix = 'pre'
      base = 'master'
    elsif br != "master"
      logger.error "Couldn't parse branch '#{br}'! Just using DrushDeploy::VERSION"
    end

    if git.diff('HEAD', path).size > 0
      logger.info "Working directory is dirty, building 'build' version"
      needs_build = true
    end

    version = VERSION
    version += pre(git, pre_prefix, base) if pre_prefix
    version += build if needs_build
    version
  end
  private

  def self.build
    ".build."+Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def self.pre(git,prefix,base)
    commits = git.lib.log_commits(:between =>[base,'HEAD']).size
    if commits > 0
      ".#{prefix}.#{commits}"
    else
      ""
    end
  end
end
