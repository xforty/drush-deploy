require 'capistrano'
require 'drupal_deploy/error'
require 'drupal_deploy/configuration'
require 'yaml'

module DrupalDeploy
  class Database
    class Error < DrupalDeploy::Error; end

    REQUIRED_KEYS = %w(driver database username password
                       admin_username admin_password prefix).map &:to_sym
  
    def initialize(config)
      @config = config
    end

    def method_missing(sym, *args, &block)
      if @config.respond_to?(sym)
        @config.send(sym, *args, &block)
      else
        super
      end
    end

    def configure
      databases_path.find do |val|
        load_path val
        REQUIRED_KEYS.all? {|k| databases.key? k}
      end
    end

    def load_path(path)
      logger.info "Trying to load database setting from #{path.inspect}"
      if path !~ /^[\/~]/
        path = latest_release+"/"+path
      end
      if path =~ /.php$/
        load_php_path path
      elsif path =~ /.yml$/
        load_yml_path path
      else
        throw Error.new "Unknown file type: #{path}"
      end
    end

    def load_php_path(path)
      prefix = ''
      if path.sub!(/^~/,'')
        prefix = "getenv('HOME')." 
      end

      script = <<-END.gsub(/^ */,'')
        <?php
        $filename = #{prefix}'#{path}';
        if( file_exists($filename) ) {
          require_once($filename);
          if( isset($databases) ) {
            print serialize($databases);
          }
        } 
      END
      put script, '/tmp/load_db_credentials.php', :once => true
      resp = capture "#{drush_bin} php-script /tmp/load_db_credentials.php"
      if !resp.empty?
        set :databases, deep_merge(DrupalDeploy::Configuration.unserialize_php(resp),databases)
      end
    end

    def load_yml_path(path)
      prefix = ''
      if path.sub!(/^~/,'')
        prefix = '"$HOME"'
      end

      yaml =  capture("[ ! -e #{prefix}'#{path}' ] || cat #{prefix}'#{path}'")
      if !yaml.empty?
        credentials = YAML.load yaml
        set :databases, deep_merge(DrupalDeploy::Configuration.normalize_value(credentials),databases)
      end
    end

    private

    def deep_merge(h1,h2)
      merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      h1.merge(h2, &merger)
    end

  end
end
