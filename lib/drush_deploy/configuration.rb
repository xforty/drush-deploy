require 'drush_deploy/error'

require 'shellwords'
require 'php_serialize'
require 'net/ssh/config'

module DrushDeploy
  class Configuration
    class Error < DrushDeploy::Error; end
    attr_reader :aliases, :drush

    def self.unserialize_php(php)
      normalize_value PHP.unserialize(php)
    end

    def self.normalize_value(val) 
      if val.is_a? Hash
        val.inject({}) do |result,(k,v)|
          result[k.gsub(/-/,'_').to_sym] = normalize_value(v)
          result
        end
      elsif val.is_a? Array
        val.map &:normalize_value
      else
        val
      end
    end

    def initialize(drush = 'drush')
      @drush = drush
      load_configuration
    end

    def load_configuration
      @aliases = site_aliases
      @aliases.each do |name,conf|
        if conf['ssh-options']
          conf['ssh-options'] = Net::SSH::Config.translate translate_ssh_options(conf['ssh-options'])
        end
        if conf['roles']
          if conf['roles'].is_a? String
            conf['roles'] = conf['roles'].split(/ *, */)
          end
          conf['roles'] = conf['roles'].map{ |r| r.strip.to_sym }
        end
        if conf['attributes']
          # Recursively turn all hash keys into symbols
          mapper = lambda do |h|
            h.inject({}) {|result,(k,v)| result[k.to_sym] = (v.is_a?(Hash) ? mapper(v) : v); result }
          end
          conf['attributes'] = mapper.(conf['attributes'])
        end
      end
    end

    def site_aliases
      PHP.unserialize(`#{@drush} eval 'print serialize(_drush_sitealias_all_list());'`).delete_if {|k,v| k == '@none'}
    end

    def lookup_site(sitename)
      @aliases[sitename] || @aliases['@'+sitename]
    end

    
    def load_source(sitename)
      site = lookup_site(sitename)
    end

    private

    # Takes a set of ssh command line options and converts them into a hash of
    # equivelent ssh_config settings.
    # This can then be fed to Net::SSH::Config#translate to get the Net::SSH
    # equivalent settings hash
    def translate_ssh_options(options)
      words = Shellwords.split(options)
      option_hash = {}
      until words.empty?
        word = words.shift
        if word =~ /^-/
          word[1..-1].chars do |c|
            case c
            when 'C'
              option_hash["compression"] = true
            when 'i'
              option_hash["identityfile"] = words.shift
            when 'p'
              option_hash["port"] = words.shift
            when 'o'
              option_hash.store(*(words.shift.split(/=/).tap {|opt| opt[0].downcase!}))
            end
          end
        else
          throw Error.new "Unexpected argument #{word}"
        end
      end
      option_hash
    end

      end

  end
end
