class Category
  attr_accessor :action, :description
  
  def initialize( description, action, predicate = Proc.new { |x| true } )
    @description = description
    @action = action
    @predicate = predicate
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
end
