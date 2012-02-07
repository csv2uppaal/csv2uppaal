#!/usr/bin/env ruby

require 'csv'
require 'pp'

module Csv2Xml
  
  extend self

  def self.convert(csv_file)
    # To check for syntax errors
    @valid_first_cols = ["PROTOCOL", "ROLE", "STATES", "OUT", "IN", nil]

    # It has to keep track of the used messages
    @collected_messages = []
    @collected_states = Hash.new {|hash, key| hash[key] = Array.new}
    @roles = []
    @states = Hash.new
    @rules = Hash.new {|hash, key| hash[key] = Array.new}
    @messages_ord = Hash.new
    
    if CSV.const_defined? :Reader # Using CSV (1.8) or FasterCSV (1.9)
      csv_rows = CSV.open(csv_file, 'r', ';').to_enum
    else 
      csv_rows = CSV.read(csv_file, :col_sep=>";")
    end
	
    csv_rows.each do |row|
      case row[0]
        when /^PROTOCOL$/i
          raise SyntaxError, "Only one protocol per file is allowed" if @protocol_name
          @protocol_name = row[1]
          @protocol_medium = row[2]
          @protocol_capacity = row[3]

        when /^ROLE$/i
          @roles.push row[1]

        when /^STATES$/i
          @states[@roles.last] = row[2..-1].compact.map {|s| s.split(/(\*)/)}

          # This guarantees all declared states even if unused be collected
          @collected_states[@roles.last] |= @states[@roles.last].map {|s, f| s}

        when /^(OUT|IN)(\*?)$/i
          message_1 = row[1]
          row[2..-1].each_with_index do |c, ix|
            next unless c  # Jump nil cells (if no rule is set for that specific msg/state combination)
            message_2, next_state = c.split(",")
            current_state = @states[@roles.last][ix][0]
            if row[0] =~ /OUT/i
              rule_type         = :outbound
              send_message      = message_1
              received_message  = message_2
              if row[0] =~ /(\*)$/
                @messages_ord[send_message] = :unordered
              end
            else
              rule_type         = :inbound
              received_message  = message_1
              send_message      = message_2
              if row[0] =~ /(\*)$/
                @messages_ord[received_message] = :unordered
              end
            end

            @rules[@roles.last].push   :rule_type        => rule_type,
                                       :send_message     => send_message,
                                       :received_message => received_message,
                                       :current_state    => current_state,
                                       :next_state       => next_state
            @collected_messages |= [received_message, send_message] # collecting the valid messages (globally)
            @collected_states[@roles.last] |= [current_state, next_state]
            # Think about some sanity checking here
          end
        when nil  # Just ignore
        else
          raise SyntaxError, %|The String #{row[0]} is not valid as first collumn!|
      end
    end

    @collected_messages -= ['']
    @collected_messages.sort!
    puts          %|<protocol name="#{@protocol_name}" medium="#{@protocol_medium}" capacity="#{@protocol_capacity}">|
    puts          %|  <messages>|
    @collected_messages.each do |m|
      puts        %|     <message#{@messages_ord[m] ? ' type="unordered"' : ''}>#{m}</message>|
    end
    puts          %|  </messages>|
    puts
    @roles.each do |role|
      puts        %|  <role name="#{role}">|
      puts        %|    <states>|
      puts        %|      <state type="initial">#{@states[role][0][0]}</state>|
      remaining_states = (@collected_states[role] - @states[role][0][0,1]) | ["Invalid"] # Used or not, "Invalid" is always there.
      remaining_states.each do |state|
#        p @states[role]
#        p state
        state_info = @states[role].assoc(state)
#        p state_info
        if state_info.nil?
          raise "State '#{state}' used but not previously declared (check for typos)" unless state == "Invalid"
          puts    %|      <state>#{state}</state>|
        elsif state_info[1] == '*'
          puts    %|      <state type="final">#{state}</state>|
        else
          puts    %|      <state>#{state}</state>|
        end
      end
      puts        %|    </states>|
      @rules[role].each do |rule|
        case rule[:rule_type]
          when :outbound
            puts  %|    <rule id="#{rule[:current_state]}__#{rule[:send_message]}__OUTBOUND">|  
          when :inbound
            puts  %|    <rule id="#{rule[:current_state]}__#{rule[:received_message]}__INBOUND">|
        end
        puts      %|      <pre>|
        puts      %|        <current_state>#{rule[:current_state]}</current_state>| unless rule[:current_state].empty?
        puts      %|        <received_message>#{rule[:received_message]}</received_message>| unless rule[:received_message].empty?
        puts      %|      </pre>|
        puts      %|      <post>|
        puts      %|        <send_message>#{rule[:send_message]}</send_message>| unless rule[:send_message].empty?
        puts      %|        <next_state>#{rule[:next_state]}</next_state>| unless rule[:next_state].empty?
        puts      %|      </post>|
        puts      %|    </rule>|
        puts
      end
      puts        %|  </role>|
    end
    puts          %|</protocol>|
  end
end

Csv2Xml.convert(ARGV[0])


