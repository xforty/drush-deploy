require 'drush/error'

require 'shellwords'
require 'php_serialize'
require 'net/ssh/config'

module Drush
  class Configuration
    class Error < Drush::Error; end
    attr_reader :aliases, :drush

    def initialize(drush = 'drush')
      @drush = drush
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
              option_hash["compression"] = 1
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

    def handle_option(sources,keys)
      sources.inject(nil) do |dest,source|
        source_val = keys.inject(source) {|h,k| h ? h[k] : nil}
        yield dest,source_val
      end
    end

    def copy_option(dest,sources,keys)
      dest_val = handle_option(sources,keys) {|*a| yield *a}
      if dest_val
        keys.inject(dest).with_index do |h,k,i|
          if i+1 = keys.size
            h[k] = dest_val
          else
            h[k] = {} unless h[k]
          end
          h[k]
        end
      end
    end

  end
end
