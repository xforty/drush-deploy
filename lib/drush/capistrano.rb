require 'drush/error'
require 'drush/configuration'

require 'railsless-deploy'

module Drush
  class Capistrano
    class Error < Drush::Error; end

    def initialize
      @cap_config = Capistrano::Configuration.instance(:must_exist)

      if @cap_config.exists? :drush
        @drush_config = Drush::Configuration.new @cap_config[:drush]
        @drush_config.load_configuration
        @cap_config.logger.info "Loaded sites: #{@drush_config.aliases.join(", ")}"
      else
        @drush_config = Drush::Configuration.new
        @cap_config.set :drush, @drush_config.drush
      end
      @cap_config.logger.info "Using drush at \"#{@drush_config.drush}\""
    end

    # Take a sitename and setup it's settings as the target host
    def load_target(sitename)
      site = @drush_config.lookup_site(sitename)
      return nil unless site

      if site["site-list"]
        # Site group
        site["site-list"].each {|member| load_target member}
      else
        @cap_config.load do
          # Verify existence of required settings
          if %w(remote-host roles).all? {|key| site[key]}
            # Setup servername. Use <username>@ and :<port> syntax in servername instead of
            # :user and ssh_option[:port] to allow for different values per host.
            servername = sites["remote-host"]

            servername = site["remote-user"]+'@'+servername if site["remote-user"]

            if site["ssh-options"].try(:[],:port)
              servername += ':'+site["ssh-options"][:port].to_s
              ssh_options.delete :port
            end

            server_args = [servername, *sites["roles"]]
            server_args += sites["attributes"] if sites["attributes"]

            server *server_args

            # If global settings are already set, don't overwrite
            ignore = []
            if site["ssh-options"]
              if ssh_options.empty?
                ssh_options = site["ssh-options"]
              elsif ssh_options != site["ssh-options"]
                ignore << "ssh-options"
              end
            end
            if site["root"]
              if !defined?(deploy_to)
                set :deploy_to, site["root"]
              elsif deploy_to != site["root"]
                ignore << "root"
              end
            end
            # Print warnings when ignoring settings
            unless ignore.empty?
              logger.warn "Ignoring options #{ignore.join(", ")} for site #{sitename} because it is already set to a different value"
            end
          else
            logger.info "Skipping site \"#{sitename}\" because missing a required setting."
          end
        end
      end
    end
  end
end
