class State < ProtocolObject

  @@states = Hash.new { |hash, ix| hash[ix] = Array.new }

  attr_accessor :state, :role

  alias :name :state
  alias :to_sym :state

  def initialize(args, text, parent)

    @initial = true if args["type"] == "initial"
    @final = true if args["type"] == "final"

    @state = text.upcase.to_sym
    super
  
    if @parent.parent.parent.is_a? Role
      role = @parent.parent.parent
    elsif @parent.is_a? Role
      role = @parent
    else
      raise "Can't find States's Role"
    end

    @@states[role] |= [@state]
    @role = role

  end

  def self.states
    @@states
  end

  def initial?
    @initial
  end
  
  def final?
    @final
  end

end
