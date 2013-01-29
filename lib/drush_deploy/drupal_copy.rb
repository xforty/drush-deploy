require 'capistrano/recipes/deploy/strategy/copy'

module DrushDeploy
  module Strategy
      # Implements the deployment strategy that uses copy.  Override 
      class DrupalCopy < ::Capistrano::Deploy::Strategy::Copy
      
        # SCM::None Class?
        class Source

          attr_reader :configuration

          def initialize(source)
            @source = source 
          end
          
          def method_missing(method, *args, &block)
            @source.send(method, *args, &block)
          end
          
          def respond_to_missing?(method)
            @source.send(method)
          end
          
          def checkout(revision, destination)
          
            execute = []
            makefile = variable(:makefile)
            
            # Copy the :repository directory in to the :desitnation directory
            # if the :make_clean option is false
            if variable(:make_clean) == false
              # @TODO: Do we care about windows?
              # execute << !Capistrano::Deploy::LocalDependency.on_windows? ? "cp -R #{repository} #{destination}" : "xcopy #{repository} \"#{destination}\" /S/I/Y/Q/E"
              execute << "cp -R #{repository} #{destination}"
            else
              execute << "mkdir -p #{destination}"
              makefile = "$OLDPWD/'#{makefile}'"
            end
            
            build_cmd = "#{variable(:drush)} make #{variable(:make_args)} #{makefile} ."
    
            # :auto uses copy strategy then builds if the makefile is in place
            if variable(:make) == :auto
              build_cmd = "cd #{destination} && [ -f index.php ] || { [ -f #{makefile} ] && #{build_cmd}; }"
            end
            
            # Run drush make if :make
            if variable(:make)
              execute << build_cmd
            end
    
            execute.join(" && ")
          end
          
          alias_method :export, :checkout
          alias_method :sync, :checkout
    
        end
        
        def source
            Source.new super
        end
      end
  end
end 