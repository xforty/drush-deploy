module DrushDeploy
  module Paths
    def self.root(path = '')
      File.expand_path('../../../' + path,__FILE__)
    end

    def self.bin(path = '')
      root('bin/' + path)
    end

    def self.lib(path = '')
      root('lib/' + path)
    end

    def self.recipe(path)
      root('lib/drush_deploy/recipes/' + path + '.rb')
    end
  end
end
