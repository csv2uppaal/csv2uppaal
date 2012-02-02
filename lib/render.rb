class Render
  
  include SUHelperMethods
  
  class << self
    undef new
  end  
  
  def self.renderize(protocol)
    @protocol = protocol
	
    dir_path = File.dirname(Opt.filename) # TODO: Check OUT_DIR - the same
    # TODO protocol.name is different of protocol_name (change this).
    protocol_name = Opt.protocol

    # This 'batch' opening cause a very dificult to track bug. 
    # The files remainded open even after they were not needed anymore

    uppaal_file               = File.open("#{dir_path}/#{protocol_name}.xml", "w")
    query_file                = "#{dir_path}/#{protocol_name}.q"
    query_file_overflow       = "#{dir_path}/#{protocol_name}-boundedness.q"
    query_file_invalid        = "#{dir_path}/#{protocol_name}-correctness.q"
    query_file_deadlock       = "#{dir_path}/#{protocol_name}-deadlock_freeness.q"
    query_file_ended          = "#{dir_path}/#{protocol_name}-termination.q"
    query_file_overflow_timed = "#{dir_path}/#{protocol_name}-boundedness_under_fairness.q"
    query_file_ended_timed    = "#{dir_path}/#{protocol_name}-termination_under_fairness.q"
    
    # Protocol analysis and statistics printed out 
    STDERR.puts " " 
    STDERR.puts "********************" 
    STDERR.puts "Tool csv2uppaal v1.1" 
    STDERR.puts "********************" 
    STDERR.puts "  Protocol name: #{@protocol}" 
    
    case @protocol.medium_type.upcase
      when "BAG"
      STDERR.puts "  Communication: BAG (asynchronous reliable medium with reoredring)"
      when "FIFO"
      STDERR.puts "  Communication: FIFO (asynchronous reliable medium)"
      #when "LOSSY_FIFO", "LOSSY-FIFO"
      when /^lossy([-_]fifo)?$/i
      STDERR.puts "  Communication: LOSSY-FIFO (asynchronous lossy medium)"
      when /^stutt([-_]fifo)?$/i
      STDERR.puts "  Communication: STUTT-FIFO (asynchronous unreliable medium)"
      when "SET"
      STDERR.puts "  Communication: SET (asynchronous unreliable medium with reordering)"
    else  # if nothing else recognized then it is a SET
      STDERR.puts "  Communication: unknown, using SET (asynchronous unreliable medium with reordering)"
    end
    
    STDERR.puts "       Channels: #{Opt.optimize? ? "multiple" : "single"}"
    STDERR.puts "Buffer capacity: #{@protocol.medium_capacity}"
    STDERR.puts "     Role names: #{@protocol.roles.join(", ")}"
    STDERR.puts "       Messages: #{@protocol.messages.sort.join(", ")}"
    if @protocol.messages.any? { |m| m.unordered? }
      STDERR.puts " Unordered Msgs: #{@protocol.messages.select {|m| m.unordered?}.sort.join(", ")}"  
    end
    
    STDERR.puts "  "
    
    raise ArgumentError, "The input file is not a valid description of a protocol." if not @protocol.kind_of? Protocol
    
    # From now on, all 'puts' (and the othes) will go to the output file (uppaal_file) 
    $stdout = uppaal_file
    STDERR.puts "# Writing: #{File.basename(uppaal_file.path)}\n\n"
    puts SUHelperMethods::UPPAAL_XML_HEADER
    
    # "Protocol" has a to_s defined in ProtocolObject
    # And, to_s renders object.name
    # So, we can use just "protocol" that it will try to call to_s on it 
    
    # DECLARATION BEGIN
    puts "<declaration>"
   
    @protocol.roles.each do |role|
      role_name_upcase = role.name.to_s.upcase
      
      puts "\n//States of Role #{role_name_upcase}"
      puts "typedef int[0,#{State.states[role].size - 1}] State#{role_name_upcase}; "
      
      puts
      
      State.states[role].each_with_index do |state, value|
        puts "const State#{role_name_upcase} #{role_name_upcase}_#{state.to_s.upcase} = #{value}; "
      end
      
      puts
      puts "State#{role_name_upcase} st#{role_name_upcase} = #{role_name_upcase}_#{role.init_state.name.to_s.upcase};"
      puts
      
    end
    
    puts "\n//Set of Messages for all roles"
    puts "typedef int[0,#{Message.messages.size-1}] Msgs;"
    
    @protocol.messages.each_with_index do |msg, ix|
      puts "const Msgs #{msg} = #{ix};" + "#{msg.unordered? ? "  // Unordered Message" : ""}"
    end
    
    puts   
    puts <<heredoc
typedef int[0,4] Buffer_Implementation;
const Buffer_Implementation SET = 0;
const Buffer_Implementation BAG = 1;
const Buffer_Implementation STUTT_FIFO = 2;
const Buffer_Implementation FIFO = 3;
const Buffer_Implementation LOSSY = 4;
heredoc
    
    puts "\n// Fifo Channels\n"
    channels_suffixes = @protocol.roles_in_message.values.uniq.map{|r| r.join("_")}.sort
    
    puts "typedef int[0,#{channels_suffixes.size-1+1}] Channels;\n" # -1+1 just to remember that it's about an "extra" channel, "SET_CHANNEL"
    channels_suffixes.each_with_index do |chn, ix|
      puts "const Channels FIFO_CHANNEL_#{chn} = #{ix};"
    end
    puts "const Channels SET_CHANNEL = #{channels_suffixes.size};"
    
    puts "\n\n"
    
    puts "int buffer_channel(Msgs s) {"
    if Opt.optimize?
      @protocol.messages.each do |m|
        print "  if (s == #{m}) return #{@protocol.roles_str_of_msg(m)};"
        puts (m.unordered? ? "  // Unordered Message" : " ")
      end
    end
    puts "  return 0; \n}\n\n"
    
    case @protocol.medium_type.upcase
      when "BAG"
      puts "Buffer_Implementation buffer_Implementation = BAG;" 
      puts "const int BUFFER_CAPACITY = #{@protocol.medium_capacity};"
      when "FIFO"
      puts "Buffer_Implementation buffer_Implementation = FIFO;" 
      puts "const int BUFFER_CAPACITY = #{@protocol.medium_capacity};"
      #     when "LOSSY_FIFO", "LOSSY-FIFO"
      #       puts "Buffer_Implementation buffer_Implementation = LOSSY_FIFO;" 
      #       puts "const int BUFFER_CAPACITY = #{protocol.medium_capacity};"
      when /^lossy([-_]fifo)?$/i # Matches LOSSY-FIFO and LOSSY_FIFO, preventing typos errors
      puts "Buffer_Implementation buffer_Implementation = LOSSY;"
      puts "const int BUFFER_CAPACITY = #{@protocol.medium_capacity};"
      when /^stutt([-_]fifo)?$/i # Matches STUTT-FIFO and STUTT_FIFO, preventing typos errors
      puts "Buffer_Implementation buffer_Implementation = STUTT_FIFO;"
      puts "const int BUFFER_CAPACITY = #{@protocol.medium_capacity};"
    else  # if nothing else recognized then it is a SET
      puts "Buffer_Implementation buffer_Implementation = SET;" 
      puts "const int BUFFER_CAPACITY = 1;"
    end
    
    puts <<heredoc
bool overflow = false;

typedef int[0,BUFFER_CAPACITY-1] Buffer;
typedef int [0,BUFFER_CAPACITY] BufferSize;
BufferSize bufferSize[Channels];

bool msg_SET[Msgs];
int msg_BAG[Msgs];
Msgs msg_FIFO[Channels][Buffer];

// Finally set the minimum delay and tire-outs for the retransmission of messages 
// This is relevant only for the termination property and MIN_DELAY should be 
// smaller or equal than TIRE_OUT
// For boundedness and correctness checks, the constants should be both set to 0

const int MIN_DELAY = #{Opt.min_delay || 1};
const int TIRE_OUT = #{Opt.tire_out || 3};

void Send_Msg(Msgs s) {
int i;
//SET 
if (buffer_Implementation == SET) msg_SET[s] = true;
//BAG 
if (buffer_Implementation == BAG) {
        if (msg_BAG[s] == BUFFER_CAPACITY) overflow = true;
                else msg_BAG[s]++; }
//STUTT_FIFO 
if (buffer_Implementation == STUTT_FIFO)        {
   if (buffer_channel(s) == SET_CHANNEL) { msg_SET[s] = true;}
   else
   { if (bufferSize[buffer_channel(s)] == BUFFER_CAPACITY) overflow = true;
             else
    {if (msg_FIFO[buffer_channel(s)][0] != s and bufferSize[buffer_channel(s)]&gt;0) {
  for (i=bufferSize[buffer_channel(s)]-1; i&gt;=0; i--) 
             msg_FIFO[buffer_channel(s)][i+1] = msg_FIFO[buffer_channel(s)][i];
                bufferSize[buffer_channel(s)]++; msg_FIFO[buffer_channel(s)][0] = s; 
                }
                if (bufferSize[buffer_channel(s)]==0) 
             { bufferSize[buffer_channel(s)]++; msg_FIFO[buffer_channel(s)][0] = s; }
              }               
   }
}
//FIFO 
if (buffer_Implementation == FIFO) {
       if (buffer_channel(s) == SET_CHANNEL) { msg_SET[s] = true;}
       else
       { if (bufferSize[buffer_channel(s)] == BUFFER_CAPACITY) overflow = true;
                else
       { for (i=bufferSize[buffer_channel(s)]-1; i&gt;=0; i--) 
            msg_FIFO[buffer_channel(s)][i+1] = msg_FIFO[buffer_channel(s)][i];
                                bufferSize[buffer_channel(s)]++; 
                                msg_FIFO[buffer_channel(s)][0] = s;}
                }
      }
// LOSSY FIFO 
if (buffer_Implementation == LOSSY) {
       if (buffer_channel(s) == SET_CHANNEL) { msg_SET[s] = true;}
       else
       { if (bufferSize[buffer_channel(s)] == BUFFER_CAPACITY) overflow = true;
                else
       { for (i=bufferSize[buffer_channel(s)]-1; i>=0; i--) 
            msg_FIFO[buffer_channel(s)][i+1] = msg_FIFO[buffer_channel(s)][i];
                                bufferSize[buffer_channel(s)]++; 
                                msg_FIFO[buffer_channel(s)][0] = s;}
                }
      }
}

bool Receive_Msg(Msgs r) {
int i;
//SET 
if (buffer_Implementation == SET) return msg_SET[r];
//BAG 
if (buffer_Implementation == BAG) return(msg_BAG[r] &gt;= 1);
//STUTT_FIFO 
if (buffer_Implementation == STUTT_FIFO) {
 if (buffer_channel(r) == SET_CHANNEL) return msg_SET[r];
    else { for (i=bufferSize[buffer_channel(r)]-1; i&gt;=0; i--) 
                if (msg_FIFO[buffer_channel(r)][i] == r) return true;
                        return false;}
}
//FIFO 
if (buffer_Implementation == FIFO) {
 if (buffer_channel(r) == SET_CHANNEL) return msg_SET[r];
    else{ if (bufferSize[buffer_channel(r)]==0) return false;
        return (msg_FIFO[buffer_channel(r)][bufferSize[buffer_channel(r)]-1] == r);} }
//LOSSY 
if (buffer_Implementation == LOSSY) {
 if (buffer_channel(r) == SET_CHANNEL) return msg_SET[r];
    else { for (i=bufferSize[buffer_channel(r)]-1; i>=0; i--) 
                if (msg_FIFO[buffer_channel(r)][i] == r) return true;
                        return false;}
}
return false; 
}

void Received_Msg(Msgs r) {
int i;
//SET 
//do nothing (it is duplicating)
//BAG
if (buffer_Implementation == BAG) msg_BAG[r]--;
//STUTT_FIFO 
if (buffer_Implementation == STUTT_FIFO) { 
   if (buffer_channel(r) != SET_CHANNEL) 
      { i = bufferSize[buffer_channel(r)]-1; 
        while ( msg_FIFO[buffer_channel(r)][i] != r) 
           {i--; bufferSize[buffer_channel(r)]--;}
         }
}
//FIFO 
if (buffer_Implementation == FIFO) {
   if (buffer_channel(r) != SET_CHANNEL) 
       { bufferSize[buffer_channel(r)]--; }}
//LOSSY
if (buffer_Implementation == LOSSY) { 
   if (buffer_channel(r) != SET_CHANNEL) 
      { i = bufferSize[buffer_channel(r)]-1; 
        while ( msg_FIFO[buffer_channel(r)][i] != r) 
           {i--; bufferSize[buffer_channel(r)]--;}
         } bufferSize[buffer_channel(r)]--;
}
}
heredoc
    
    puts "</declaration>"
    
    # DECLARATION END
=begin    
    rtxclocks = Hash.new
    allrtxclocks = Array.new
    @protocol.roles.each_with_index do |role, role_ix|
      rtxclocks[role] = role.rules.select{|rule| rule.retrans?}.map {|rule| "x_#{rule}"}
      allrtxclocks += rtxclocks[role]
    end
=end
    # TEMPLATE BEGIN
    @protocol.roles.each_with_index do |role, role_ix|
      role_name = role.name.to_s
      role_name_upcase = role.name.to_s.upcase
      
      puts "<template>"
      puts "<name>#{role.name}</name>"
      puts "<declaration>"
      if Opt.timed?
#        rtxcstr = rtxclocks[role].join(",\n    ")
#        puts "  clock #{rtxcstr},\n    y;"
         puts "clock x, y;"
      end
      
      role.rules.each_with_index do |rule, ix| 
        rule_number = ix+1  # legacy code, now the name of the guard/action is different
        
        if Opt.timed?
          if rule.retrans?
            puts ""
            puts "// Retransmission Transition "
          else
            puts ""
            puts "// Regular Transition "
          end
        end
        
        puts
        puts "bool guard__#{rule.name}() {"
        print "  return "
        
        if rule.condition.nil? then 
          puts " 1"
        else
          str = condition_strings(rule).join(" &amp;&amp; ")
          print	 str
        end
        
        puts ";\n}\n"
        
        puts
        puts "void action__#{rule.name}() {"
        str = action_strings(rule).join
        puts  (str ? str : ";")
        puts "}\n"
        puts 
      end
      puts "</declaration>"
      puts
      
      rules_size = role.rules.size
      nail_arc_min = 30
      radius_min = 250
      nail_arc_default = (2.0*Math::PI*radius_min)/rules_size
      nail_arc = [nail_arc_default, nail_arc_min].max
            
      radius_default = ((nail_arc*rules_size)/(2.0*Math::PI)).to_int
      radius = [radius_min, radius_default].max


      
#      radius = 300
      id_start = "id_#{role}_START"
      id_invariant = "id_#{role}_INVARIANT"
#      id_invalid = "id_#{role}_INVALID"
      
      start_x = 0
      start_y = (radius+200)
      
#      invalid_x = (-radius-300)
#      invalid_y = 0
      if Opt.timed?

#        artxcond = rtxclocks[role].map {|cl| "#{cl}&lt;=TIRE_OUT+1" }.join("&amp;&amp;")
        
        puts "<location id=\"#{id_invariant}\" x=\"0\" y=\"0\">"
        puts "  <label kind=\"invariant\" x=\"15\" y=\"0\">x&lt;=TIRE_OUT+1</label>"
        puts "</location>"
              
  #      puts "<location id=\"#{id_invalid}\" x=\"#{invalid_x}\" y=\"#{invalid_y}\">"
  #      puts "  <name x=\"#{invalid_x+15}\" y=\"#{invalid_y}\">INVALID</name>"
  #      puts "</location>"
        
        puts "<location id=\"#{id_start}\" x=\"#{start_x}\" y=\"#{start_y}\">"
        puts "  <name x=\"#{start_x+15}\" y=\"#{start_y}\">START</name><committed/>"
        puts "</location>"
        puts
        puts "<init ref=\"#{id_start}\"/>"
        puts
        
        puts "<transition>"
        puts "  <source ref=\"#{id_start}\"/><target ref=\"#{id_invariant}\"/>"
        puts "</transition>"
      else
        puts "<location id=\"#{id_start}\" x=\"0\" y=\"0\">"
        puts "  <name x=\"#{start_x+15}\" y=\"#{start_y}\">START</name><committed/>"
        puts "</location>"
        puts
        puts "<init ref=\"#{id_start}\"/>"
        puts

      end
        
      
      
      
      # First adding the special loop for LOSSY_FIFO
      # puts "<transition>"
      # puts "  <source ref=\"id#{role_ix}\"/><target ref=\"id#{role_ix}\"/>"
      # puts "  <label kind=\"guard\" x=\"250\" y=\"100\">bufferSize&gt;0 &amp;&amp; buffer_Implementation==LOSSY_FIFO</label>"
      # puts "  <label kind=\"assignment\" x=\"250\" y=\"80\">bufferSize--</label>"
      # puts %Q[<nail x=\"400\" y=\"90\"/><nail x=\"400\" y=\"70\"/>]
      # puts "</transition>"
      # puts
      
      # For each rule one transition

      role.rules.each_with_index do |rule, ix|
        label_radius = 1.5
        nail_center = nail_arc * ix
        nail_1, nail_2 = nail_center + 0.02, nail_center - 0.02
        nail_center_x = Math.cos(nail_center)*radius 
        nail_center_y = Math.sin(nail_center)*radius
        nail_1_x = (Math.cos(nail_1)*radius).floor
        nail_1_y = (Math.sin(nail_1)*radius).floor
        nail_2_x = (Math.cos(nail_2)*radius).floor
        nail_2_y = (Math.sin(nail_2)*radius).floor
    
        if Opt.timed?
#          otherrtxcond = (allrtxclocks-["x_#{rule}"]).map {|cl| "#{cl}&lt;=TIRE_OUT+1" }.join("&amp;&amp;")
#          otherrtxcond += "y&gt;=MIN_DELAY"

          if rule.retrans?
            puts "<!-- Retransmission Transition -->"
          else
            puts "<!-- Regular Transition -->"
          end
          puts "<transition>"
          puts "  <source ref=\"id_#{role}_INVARIANT\"/><target ref=\"id_#{role}_INVARIANT\"/>"
          print "  <label kind=\"guard\" x=\"#{(nail_center_x*label_radius).floor-50}\" y=\"#{(nail_center_y*label_radius).floor+8}\">guard__#{rule.name}()"
          if rule.retrans?
            print "&amp;&amp;x&lt;=TIRE_OUT&amp;&amp;y&gt;=MIN_DELAY"
          end
          print "</label>\n"
          print "  <label kind=\"assignment\" x=\"#{(nail_center_x*label_radius).floor-50}\" y=\"#{(nail_center_y*label_radius).floor-8}\">action__#{rule.name}()"

#          this_role_rtx_assig = rtxclocks[role].map {|cl| "#{cl}=0" }.join(",")
          if rule.retrans?
#            raise "clocks handling error" if (rtxclocks[role].size) == ((rtxclocks[role]-["x_#{rule}"]).size)
#            otherrtxassig = (rtxclocks[role]-["x_#{rule}"]).map {|cl| "#{cl}=0" }.join(",")
#            print ",#{otherrtxassig},y=0"
            print ",y=0"
          else
#            print ",#{this_role_rtx_assig}"
            print ",x=0"
          end

          print "</label>\n"
          puts %Q[  <nail x="#{nail_1_x}" y="#{nail_1_y}"/><nail x="#{nail_2_x}" y="#{nail_2_y}"/>]
          puts "</transition>"
          puts
        else
          puts "<transition>"
          puts "  <source ref=\"#{id_start}\"/><target ref=\"#{id_start}\"/>"
          print "  <label kind=\"guard\" x=\"#{(nail_center_x*label_radius).floor-50}\" y=\"#{(nail_center_y*label_radius).floor+8}\">guard__#{rule.name}()"
          print "</label>\n"
          print "  <label kind=\"assignment\" x=\"#{(nail_center_x*label_radius).floor-50}\" y=\"#{(nail_center_y*label_radius).floor-8}\">action__#{rule.name}()"
          print "</label>\n"
          puts %Q[  <nail x="#{nail_1_x}" y="#{nail_1_y}"/><nail x="#{nail_2_x}" y="#{nail_2_y}"/>]
          puts "</transition>"
          puts
        end
      end
      puts "</template>"
    end
    print "\n<system>system "
    str = @protocol.roles.collect{|r| r.name}.inject do |r_prev, r_next|
      "#{r_prev}, #{r_next}"
    end
    print str        
    print ";</system>\n"
    puts UPPAAL_XML_FOOTER
    
    ###############
    # QUERY_FILES #
    ###############
    
    query_overflow_timed = query_overflow    

    if Opt.timed?
      render query_overflow_timed, :output => query_file_overflow_timed
      render query_ended_timed,    :output => query_file_ended_timed
      render query_overflow_timed+query_ended_timed, :output => query_file
    else
      render query_invalid,  :output => query_file_invalid
      render query_deadlock, :output => query_file_deadlock
      render query_overflow, :output => query_file_overflow
      render query_ended,    :output => query_file_ended
      render query_overflow+query_invalid+query_deadlock+query_ended, :output => query_file
    end

    ensure
      #TODO: A better handling (not messing with) of STDOUT
      uppaal_file.close
      $stdout = STDOUT
  end
  
  private
  
  def self.condition_strings(rule)
   (rule.condition.states + rule.condition.messages).collect do |stat_or_msg|
      case stat_or_msg
        when State
        role_name = stat_or_msg.role.to_s.upcase
          "st#{role_name} == #{role_name}_#{stat_or_msg.name.to_s.upcase}"
        when Message
         "Receive_Msg(#{stat_or_msg})"
      end
    end
  end
  
  def self.action_strings(rule)
    action_str =
     (rule.action.states + rule.action.messages).collect do |stat_or_msg|
      case stat_or_msg
        when State
        role_name = stat_or_msg.role.to_s.upcase
          "  st#{role_name} = #{role_name}_#{stat_or_msg.name.to_s.upcase};\n"
        when Message
          "  Send_Msg(#{stat_or_msg});\n"
      end
    end
    received_message_str = 
     (rule.condition.messages).collect do |msg|
      "  Received_Msg\(#{msg}\);\n"
    end
    received_message_str + action_str
  end
  
  private
  
  def self.render(str, options)
    File.open(options[:output], 'w') do |f|
      f.puts "// This file was generated by csv2uppaal\n\n"
      f.puts str
    end
  end
  
  ##################
  # QUERY_OVERFLOW #
  ##################
  
  def self.query_overflow
<<heredoc
/*
Check for boundedness; if there is a buffer overflow (answer no) then you may try to increase the BUFFER_SIZE constant in the global model declarations.
*/
A[] !overflow

heredoc
  end
  
  ##################
  # QUERY_INVALID #
  ##################
  
  def self.query_invalid
    str = <<heredoc
/*
Check correctness (no invalid states are reachable); if the answer is no, then model can reach invalid states.
*/
heredoc
    
    str += "A[] "
    role_conditions = @protocol.roles.map do |r|
       "st#{r.to_s.upcase}!=#{r.to_s.upcase}_INVALID"
    end.join(" && ")
      str += "((#{role_conditions}) || overflow)\n\n"
  end

##################
# QUERY_DEADLOCK #
##################

  def self.query_deadlock
  
    str = <<heredoc
/*
Check for deadlock-freeness; this property checks whether the protocol contains a deadlock situation where at least one of the roles did not reach the Ended state.
*/
heredoc
    
    str += "A[] !deadlock || overflow || "
    
    role_conditions = 
    @protocol.roles.map do |r|
      r_str = r.final_states.map do |s|
           "st#{r.to_s.upcase}==#{r.to_s.upcase}_#{s.to_s.upcase}"
      end
      if r_str.empty?
           "false"
      else
           "(#{r_str.join(" || ")})"
      end
    end.join(" && ")
    str += "(#{role_conditions})\n\n"
  end
    
    ###############
    # QUERY_ENDED #
    ###############
    
  def self.query_ended
    str = <<heredoc
/*
Check for termination; the possibility that all roles reach at least one of their final states.
*/
heredoc


    str += "E<> "
    role_conditions = 
    @protocol.roles.map do |r|
      r_str = r.final_states.map do |s|
         "st#{r.to_s.upcase}==#{r.to_s.upcase}_#{s.to_s.upcase}"
      end
      if r_str.empty?
         "false"
      else
         "(#{r_str.join(" || ")})"
      end
    end.join(" && ")
      str += "((#{role_conditions}) && !overflow)\n\n"
  end
  
  def self.query_ended_timed
    str = <<heredoc
/*
Check for termination; the possibility that all roles reach at least one of their final states.
*** Timed version query. ***
*/
heredoc


    str += "A<> "
    role_conditions = 
    @protocol.roles.map do |r|
      r_str = r.final_states.map do |s|
         "st#{r.to_s.upcase}==#{r.to_s.upcase}_#{s.to_s.upcase}"
      end
      if r_str.empty?
         "false"
      else
         "(#{r_str.join(" || ")})"
      end
    end.join(" && ")
      str += "((#{role_conditions}) || overflow)\n\n"
  end
   
end
