class ProtocolMessageError < StandardError; end
class ProtocolStateError < StandardError; end

class Protocol < ProtocolObject
  
  include SUHelperMethods
  
  attr_accessor :roles, :messages, :roles_in_message
  
  
  def initialize(args, text, parent)
    @name = args["name"]
    @medium =   Opt.medium   || args["medium"].upcase
    @capacity = Opt.capacity || args["capacity"].to_i 
    @roles = []
    @messages = [] # These are the pre-defined message (defined soon in the xml, and not "used" yet)
    @roles_in_message = Hash.new
    super
  end
  
  def <<(children)
    case children
      when Role
      children.rules.each do |rule|
        rule.condition.messages.each do |msg|
          unless @messages.include? msg
            puts "Role [#{children}] allowed messages: #{children.readable_messages.join(", ")}"
            puts "Trying to add a rule #{rule} to role #{children} with an invalid message #{msg.name}"
            raise ProtocolMessageError, msg
          end
        end
        rule.action.messages.each do |msg|
          unless @messages.include? msg
            puts "Role [#{children}] allowed messages: #{children.readable_messages.join(", ")}"
            puts "Trying to add a rule #{rule} to role #{children} with an invalid message #{msg.name}"
            raise ProtocolMessageError, msg
          end
        end
      end
      @roles |= [children]
      children.readable_messages.each do |m|
        @roles_in_message[m] = [] if @roles_in_message[m].nil?
        @roles_in_message[m] |= [children.name]
      end
      when Message
      @messages |= [children]
    end
  end 
  
  def medium_type
    @medium
  end
  
  def medium_capacity
    @capacity 
  end
  
  def roles_str_of_msg(msg)
    case msg
      when Message
        if msg.unordered?
          "SET_CHANNEL"
        else
          "FIFO_CHANNEL_"+@roles_in_message[msg.name].join("_")
        end
      when Symbol
        "FIFO_CHANNEL_"+@roles_in_message[msg].join("_")
      when NilClass
        ""
    end
  end

end
