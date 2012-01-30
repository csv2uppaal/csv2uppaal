require 'erb'

class Verifier

  def initialize(constraint)
    @constraint = constraint
    @constraint_erb = File.join "..", "view", "constraints", constraint.to_s
    @constraint_erb += ".erb"
    @trace_erb = File.join "..", "view", "trace.erb"
    @matches = Array.new
    raise Exception, "Can't read the view file #{@constraint_erb} or it doesn't exist!" unless File.readable? @constraint_erb
  end

  def verify(protocol_name=Opt.protocol, constraint=@constraint)
    path = File.join OUT_DIR, protocol_name
    path_constraint = "#{path}-#{constraint}"
    %x|#{VERIFYTA} -Y -o 2 #{Opt.trace} "#{path}.xml" "#{path_constraint}.q" 2> "#{path_constraint}.trc" > "#{path_constraint}.stdout"|
    File.foreach("#{path_constraint}.trc") do |line|

      #  Trace examples:
      #
      #  PARTICIPANT.START->PARTICIPANT.START { guard__Active__CannotComplete_p__OUTBOUND(), tau, action__Active__CannotComplete_p__OUTBOUND() }
      #  PARTICIPANT._id_PARTICIPANT_INVARIANT->PARTICIPANT._id_PARTICIPANT_INVARIANT { guard_FailingActive_Fail_p_OUTBOUND() && x <= TIRE_OUT && y >= MIN_DELAY, tau, action_FailingActive_Fail_p_OUTBOUND(), y := 0 
      #  COORDINATOR.START->COORDINATOR.START { guard__Completing__Exit_p__INBOUND(), tau, action__Completing__Exit_p__INBOUND() }

      regexp = /^\s*(\w+?)\.(\w*)->\w*\.(\w*).*guard__(\w*)__(\w*)__(OUTBOUND|INBOUND)/

      match_data = line.match regexp
      if match_data
         m = Hash.new

         m[:all_match_string],
         m[:role_name],
         m[:label1],
         m[:label2],
         m[:state],
         m[:action],
         m[:out_or_in] = match_data.to_a

         @matches.push m 
      end

    end
    @trace = ERB.new(File.read(@trace_erb), nil, '%<>').result(binding)
    @verify_log = ERB.new(File.read(@constraint_erb), nil, '%<>').result(binding)
  end
end

