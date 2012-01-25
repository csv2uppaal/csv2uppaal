class Role < ProtocolObject

  attr_accessor :rules, :init_state, :readable_messages, :states, :final_states

  def initialize(args, text, parent)

    @name = args["name"].to_sym
    @rules = []
    @readable_messages=[]
    @states=[]
    @final_states=[]
    super
  end

  def <<(children)

    case children
      when State 
        if children.role and children.role != self
          raise "Adding to role a State with a role set different from self"
        elsif # children.role is not defined yet. So, define it.
          children.role = self
        end
        @init_state = children if children.initial?
        @final_states |= [children] if children.final?
        @states |= [children.name] # Note... adding only the name (as Symbol)

      when Rule
        (children.condition.states + children.action.states).each do |st|
          unless @states.include? st.name
            puts "Role [#{self}] allowed states: #{@states.join(", ")}"
            puts "Trying to add a rule #{children} to role #{self} with an invalid state #{st.name}"
            raise ProtocolStateError, st
          end
           
        end
        @rules |= [children]
        # use only "condition" here, because only the READABLE, not the SENDABLE is registered for future use
        @readable_messages |= children.condition.messages.map{ |m| m.to_sym }
       
    end
       
  end
  
  def self.new_with_name(role_name)
    Role.new "name" => role_name
  end
  
  def max_state
    @states.size - 1
  end

  def max_msg
    @messages.size - 1
  end

end
