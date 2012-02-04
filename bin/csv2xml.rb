#!/usr/bin/env ruby

require 'csv'

module Csv2Xml
  
  extend self

  def self.convert(csv_file)
    # To check for syntax errors
    @valid_first_cols = ["PROTOCOL", "ROLE", "STATES", "OUT", "IN", nil]

    # It has to keep track of the used messages
    @collected_messages = []
    @collected_states = [] ### Atenção... não pode ser global... é por role... 
    @roles = []
    @states = Hash.new
    @rules = Hash.new {|hash, key| hash[key] = Array.new}

    CSV.foreach(csv_file, col_sep: ";") do |row|
      case row[0]
        when /^PROTOCOL$/i
          raise SyntaxError, "Only one protocol per file is allowed" if @protocol_name
          @protocol_name = row[1]
          @protocol_medium = row[2]
          @protocol_capacity = row[3]

        when /^ROLE$/i
          @roles.push row[1]

        when /^STATES$/i
          @states[@roles.last] = row[2..-1]

        when /^OUT$/i
          rule_type = :outbound
          send_message = row[1]   
          row[2..-1].each_with_index do |c, ix|
            next unless c  # Jump nil cells (if no rule is set for that specific msg/state combination)
            received_message, next_state = c.split(",")
            current_state = @states[@roles.last][ix]
            @rules[@roles.last].push   :rule_type        => rule_type,
                                       :send_message     => send_message,
                                       :received_message => received_message,
                                       :current_state    => current_state,
                                       :next_state       => next_state
            ms = [received_message, send_message]
            ms.delete("")
            @collected_messages |= ms # collecting the valid messages (globally)
          end

        when /^IN$/i
          rule_type = :inbound
          received_message = row[1]   
          row[2..-1].each_with_index do |c, ix|
            next unless c  # Jump nil cells (if no rule is set for that specific msg/state combination)
            send_message, next_state = c.split(",")
            current_state = @states[@roles.last][ix]
            @rules[@roles.last].push   :rule_type        => rule_type,
                                       :send_message     => send_message,
                                       :received_message => received_message,
                                       :current_state    => current_state,
                                       :next_state       => next_state
            ms = [received_message, send_message]
            ms.delete("")
            @collected_messages |= ms # collecting the valid messages (globally)
          end
        when nil
        else
          raise SyntaxError, %|The String #{row[1]} is not valid!|
      end
    end 
    puts          %|<protocol name="#{@protocol_name}" medium="#{@protocol_medium}" capacity="#{@protocol_capacity}">|
    puts          %|  <messages>|
    @collected_messages.each do |m|
      puts        %|     <message>#{m}</message>|
    end
    puts          %|  </messages>|
    puts
    @roles.each do |role|
      puts        %|  <role name="#{role}">|
      puts        %|    <states>|
      puts        %|      <state type="initial">#{@states[role][0]}</state>|
      @states[role][1..-1].each do |state|
        if state =~ /^(.*)\*$/
          puts    %|      <state type="final">#{$1}</state>|
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
        puts      %|      <pre>|
        puts      %|        <send_message>#{rule[:send_message]}</send_message>| unless rule[:send_message].empty?
        puts      %|        <next_state>#{rule[:next_state]}</next_state>| unless rule[:next_state].empty?
        puts      %|      </pre>|
        puts      %|    </rule>|
        puts
      end
      puts        %|  </role>|
      puts
    end
  end
end

Csv2Xml.convert(ARGV[0])


