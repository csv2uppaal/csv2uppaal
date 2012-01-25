class Action < ProtocolObject

  attr_accessor :states, :messages

  def initialize(args, text, parent)
    @states = []
    @messages = []
    super
  end

  def <<(state_or_message)
    case state_or_message
      when State
        @states << state_or_message
      when Message
        @messages << state_or_message
      else raise "Trying to concatenate a non-state, non-message to Condition"
    end
  end

end
