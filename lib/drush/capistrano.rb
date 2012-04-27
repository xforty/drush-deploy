require 'drush/error'
require 'drush/configuration'

require 'capistrano'
require 'railsless-deploy'

module Drush
  class Capistrano
    class Error < Drush::Error; end

    DEFAULT_ROLES = [:web]

    def initialize
      @cap_config = ::Capistrano::Configuration.instance(:must_exist)

      if @cap_config.exists? :drush
        @drush_config = Drush::Configuration.new @cap_config[:drush]
      else
        @drush_config = Drush::Configuration.new
        @cap_config.set :drush, @drush_config.drush
      end
      @cap_config.logger.info "Using drush at \"#{@drush_config.drush}\""
    end

    # Take a sitename and setup it's settings as the target host
    def load_target(sitename)
      site = @drush_config.lookup_site(sitename)
      @cap_config.logger.info site.inspect
      return nil unless site

      if site["site-list"]
        # Site group
        site["site-list"].each {|member| load_target member}
      else
        this = self
        @cap_config.load do
          # Verify existence of required setting
          if this.valid_target(site)
            # Setup servername. Use <username>@ and :<port> syntax in servername instead of
            # :user and ssh_option[:port] to allow for different values per host.
            servername = site["remote-host"]

            servername = site["remote-user"]+'@'+servername if site["remote-user"]

            ssh_opts = site["ssh-options"].dup
            if ssh_opts && ssh_opts[:port]
              servername += ':'+ssh_opts[:port].to_s
              ssh_opts.delete :port
            end

            attributes = site["attributes"] || {}
            (attributes[:ssh_options] ||= {}).merge! ssh_opts
            roles = site["roles"]
            unless roles
              roles = DEFAULT_ROLES
              logger.info "Using default roles #{roles.map{|r| "#{r}"}.join(", ")} for target \"#{sitename}\""
            end
            server servername, *roles, attributes

            # If global settings are already set, don't overwrite
            root = site["root"].dup
            unless root.sub! %r{/current/?$},''
              throw Error.new "root setting of site \"#{sitename}\" does not end in /current: \"#{root}\""
            end
            if root
              if !defined?(deploy_to)
                set :deploy_to, root
              elsif deploy_to != root
                logger.important "Ignoring \"root\" option for site #{sitename} because deploy_to has already been set.\n"\
                            "Note there may be only one root value for a single deploy"
              end
            end
          end
        end
      end
    end

    def valid_target(site)
      site["site-list"] || site["remote-host"]
    end

    def targets
      @drush_config.aliases.inject([]) do |list,(k,v)|
        list << k if valid_target(v)
        list
      end
    end
  end
end
