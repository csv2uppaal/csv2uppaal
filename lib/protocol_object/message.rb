class Message < ProtocolObject
 
  @@messages = []
  @@messages_types = {}
 
  def initialize(args, text, parent)
    @name = text.upcase.to_sym
    @@messages |= [@name]
    if args["type"] == "unordered" and !Opt.ignore?
      @@messages_types[@name] = :unordered
    end
    super
  end

  def self.messages
    @@messages
  end
  
  def unordered?
    @@messages_types[@name] == :unordered
  end

end

