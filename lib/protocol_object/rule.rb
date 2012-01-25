class Rule < ProtocolObject

  attr_accessor :condition, :action

  def initialize (args, text, parent)
    @name = args["id"] || args["name"]
    super
  end

  def <<(children)
  
   case children
     when Condition
       raise "Rule has already defined it's condition" if @condition
        @condition = children
     when Action
       raise "Rule has already defined it's action" if @action 
        @action = children
     else raise "Trying to concatenate a non-condition, non-action to #{self}"
   end

  end
  
  def retrans?
    (@condition.states[0].state == @action.states[0].state)
  end
  
end
