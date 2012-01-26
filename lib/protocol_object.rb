class ProtocolObject

  # name is Symbol
  attr_accessor :name

  def initialize(args, text, parent)
    @parent = parent
  end
  
  def to_s
    name.to_s
  end
  
  def to_sym
    name
  end
 
  def <=>(other)
    if other.respond_to? :to_s
      self.name.to_s <=> other.name.to_s
    else
      raise ArgumentError, "comparison of #{self.class} with #{other} failed"
    end
  end

  def parent
    @parent
  end

  # @name is the basis for equality comparison of ProtocolObject   
  def ==(other)
    if self.class != other.class
      raise "Equality comparison of objects of different classes (#{self.class} and #{other.class}) is not allowed"
    end

    # compare by name
    self.name == other.name ? true : false

  end

end

require "protocol_object/protocol"
require "protocol_object/role"
require "protocol_object/condition"
require "protocol_object/action"
require "protocol_object/message"
require "protocol_object/state"
require "protocol_object/init_state"
require "protocol_object/rule"

