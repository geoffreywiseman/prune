module Prune

  # A category indicates how a file has been classified. These are defined in the retention policy,
  # whether that be a project-specific one or the core retention policy. This is the primary abstraction
  # used to decide what to do with a file.
  class Category
    attr_accessor :action, :description
    
    def initialize( description, action, quiet = false, predicate = Proc.new { |x| true } )
      @description = description
      @action = action
      @predicate = predicate
      @quiet = quiet
    end
    
    def requires_prompt?
      case @action
      when :remove
        true
      when :archive
        true
      else
        false
      end
    end
    
    def includes?( filename )
      @predicate.call filename
    end
    
    def quiet?
      @quiet
    end
    
    def to_s
      @description
    end
    
  end
end