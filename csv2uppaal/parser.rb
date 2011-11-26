class Parser
  
  include SUHelperMethods
  
  attr_accessor :protocol
  
  def initialize(filename=nil)
    @filename = filename
    @file = File.new(@filename)
    @doc = Document.new(@file)
    @root = @doc.root
    
    # This Hash maps the xml tag, expressed here as a Symbol, 
    # to the class we should create an instance of in order
    # represent the parsed element.
    @el2class_map = { :protocol         => Protocol,
                      :role             => Role,
                      :rule             => Rule,
                      :pre              => Condition,
                      :post             => Action,
                      :states           => :container,
                      :state            => State,
                      :current_state    => State,
                      :next_state       => State,
                      :messages         => :container,
                      :message          => Message,
                      :received_message => Message,
                      :send_message     => Message,
    }
  end
  
  def class_of(element)
    raise XMLError, "The <#{element.name}> xml element not known." if @el2class_map[element.name.to_sym].nil?
    @el2class_map[element.name.to_sym]
  end
  
  def parse_element(element, parent=nil)
    # No empty tag allowed
    return nil if element.text.nil?

    text  = element.text.strip
    args  = Hash[element.attributes.collect {|x| x}]
    
    obj_class = class_of(element)
    
    if (obj_class) == :container
      obj = parent
    else
      # instantiate an object of element=>class_name
      obj = obj_class.new(args, text, parent)
    end
    # iterate through the children elements
    element.each_element do |children|
      children_obj = parse_element(children, obj)
      
      begin
       (obj << children_obj) unless children_obj.nil? # Don't add ignored tags
       
      rescue ProtocolMessageError => ex
        STDERR.puts "Message used but not predefined. File: #{@filename}"
        @file.rewind
        lines = @file.readlines
        lines.each_with_index do |l, ix|
          if l.upcase.include? ">#{ex.message.to_s}<"
            STDERR.puts " #{ix}: #{l.strip}"
          end
        end
        STDERR.puts
        exit 1
        
      rescue ProtocolStateError => ex
        STDERR.puts "State used but not predefined. File: #{@filename}"
        @file.rewind
        lines = @file.readlines
        lines.each_with_index do |l, ix|
          if l.upcase.include? ">#{ex.message.to_s}<"
            STDERR.puts " #{ix}: #{l.strip}"
          end          
        end
        STDERR.puts
        exit 1
      end
      
    end
    
    obj
  end
  
  def parse
    @protocol = parse_element(@root)
    @protocol
  end
  
  def self.parse(filename=nil)
    parser = Parser.new(filename)
    parser.parse
  end
  
end
