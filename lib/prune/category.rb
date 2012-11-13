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
