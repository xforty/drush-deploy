require 'capistrano/recipes/deploy/strategy/copy'

module DrushDeploy
  module Strategy
      # Implements the deployment strategy that uses copy.  Override 
      class DrupalCopy < ::Capistrano::Deploy::Strategy::Copy
      
        
      	class Source
      	  def initalize(source)
      	  	@source = source 
      	  end
      	  
      	  def method_missing(method, *args, &block)
      	  	@source.send(method, *args, &block)
      	  end
      	  
      	  def respond_to_missing?(method)
      	  	@source.send(method)
      	  end
      	  
      	end
      	
        # Wrap Source method --
      	def source
      		Source.new super
      	end
      	
      	
      end
  end
end	