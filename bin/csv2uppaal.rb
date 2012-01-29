#!/usr/bin/env ruby
# Takes as argument *.csv protocol description file (exported using save as from
# OpenOffice using ; as delimiers and outputs *.xml and *.q files that can
# be opened in UPPAAL; then it tries to call the command line verifyta
# (UPPAAL engine) if possible and outputs a possible error trace in text format.
# Make sure that this file and csv2xml.sh are executable via chmod +x filename

require "optparse"

libdir = File.join(File.dirname(__FILE__), '..', 'lib')

$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include? libdir

require "optparse"
require 'rexml/document'
require "helper"
require "protocol_object"
require "parser"
require "render"

include REXML


CSV2UPPAAL_VERSION = '1.2'

$options = {}

# Some defaults
$options[:trace] = "-t 0"


opts = OptionParser.new do |opts|
  opts.banner = "csv2uppaal #{CSV2UPPAAL_VERSION} - csv to uppaal conversion tool\nUsage: csv2uppaal [options] [filename.csv]"
  opts.version = CSV2UPPAAL_VERSION

  opts.on("-o", 
          "--[no-]optimize", 
          "Sets multiple channels optimization on.") do |o|
    $options[:optimize] = o
  end
  
  ms = [:Set, :Bag, :Fifo, :Stutt, :Lossy]
  m_all = ms + ms.map{|m| m.to_s.upcase} + ms.map{|m| m.to_s.downcase}
  opts.on("-m", "--medium MEDIUM", m_all,
                "Sets medium type (set, bag, fifo, lossy, stutt)") do |m|
    $options[:medium] = m.to_s.upcase
  end
  
  opts.on("-c", "--capacity VALUE", Integer, "Sets channel capacity") do |c|
    $options[:capacity] = c
  end
  
  opts.on("-t", "--trace VALUE", ["0", "1"], Integer, "Trace: 0 for any trace, 1 for shortest trace") do |t|
    $options[:trace] = "-t #{t}"
  end
  
  opts.on("-i", "--ignore", "All messages treated as ordered (ignore unordered flag)") do 
    $options[:ignore] = true
  end
  
  opts.on("-f", "--fairness", "Termination under fairness (all executions eventually terminate)" ) do 
    $options[:timed] = $options[:fairness] = true
  end
  
  opts.on("-x", "--min-delay VALUE", Integer, "Sets MIN_DELAY constant value") do |x|
    $options[:min_delay] = x
  end

  opts.on("-y", "--tire-out VALUE", Integer, "Sets TIRE_OUT constant value") do |y|
    $options[:tire_out] = y
  end


  opts.separator ""

  opts.on("-d", "--debug", "For debug puposes don't remove temporary files") do |d|
    $options[:debug] = true
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.on_tail("--version", "Show version") do
    puts opts.version
    exit
  end
  
end

opts.parse!

begin 
  ARGV.each do |arg|
    case arg
#      when /\.xml$/
#      if $options[:filename].nil?
#        $options[:filename] = arg
#      else
#        raise ArgumentError, "More than one .xml file given at commandline."
#      end

      when /(.+)\.csv$/
      if $options[:protocol].nil?
        $options[:filename] = arg
        $options[:protocol] = File.basename(arg, ".csv")
      else
        raise ArgumentError, "More than one .csv file given at commandline."
      end
      else 
        raise ArgumentError, "Invalid FileType. Only .csv files accepted."
    end
  end
rescue => e
  puts "Error: #{e.message} [#{e.class}]"
  puts opts.help
end

# filename = $options[:filename] || "inputfile.xml" 
# If no filename given, default is inputfile.xml

#$options[:filename] ||= "inputfile.xml"

unless File.exist? $options[:filename]
  raise ArgumentError, "File #{$options[:filename]} doesn't exist."
end

=begin
THIS=$(basename $0)

function usage() {
  echo -e "  $THIS 1.1"
  echo "  Usage: $THIS <filename.csv>
         $THIS -o <filename.csv> (multiple channel optimization)
         $THIS -t 0 <filename.csv> (default, finds some error trace)
         $THIS -t 1 <filename.csv> (finds the shortest error trace)
         $THIS -m [set|bag|fifo|lossy|stutt] <filename.csv> (sets the medium)
         $THIS -c capacity <filename.csv> (sets the channel capacity)
         $THIS -i all messages treated as ordered (ignore unordered flag)
         $THIS -f termination under fairness (all executions eventually terminate) 
         $THIS -x <value> sets MIN_DELAY constant
         $THIS -y <value> sets TIRE_OUT constant
         $THIS -h (shows this help)
    "
  exit -1
}

# Define all defaults
RUBY_SCRIPT_OPTS=""
TRACE_OPTION="0"
DEBUG=false
EXTENSIONS=false

while getopts "ot:m:c:hidfx:y:" OPT; do
  case $OPT in
  "o") RUBY_SCRIPT_OPTS="${RUBY_SCRIPT_OPTS} -o";;
  "m") RUBY_SCRIPT_OPTS="${RUBY_SCRIPT_OPTS} -m ${OPTARG}";;
  "t") TRACE_OPTION=$OPTARG;;
  "h") usage;;
  "c") RUBY_SCRIPT_OPTS="${RUBY_SCRIPT_OPTS} -c ${OPTARG}";;
  "i") RUBY_SCRIPT_OPTS="${RUBY_SCRIPT_OPTS} -i";;
  "d") DEBUG=true;;
  "f") RUBY_SCRIPT_OPTS="${RUBY_SCRIPT_OPTS} -f";EXTENSIONS=true;;
  "x") RUBY_SCRIPT_OPTS="${RUBY_SCRIPT_OPTS} -x ${OPTARG}";;
  "y") RUBY_SCRIPT_OPTS="${RUBY_SCRIPT_OPTS} -y ${OPTARG}";;
  "?") exit -2;;
  esac
done

if [ $TRACE_OPTION != "0" -a $TRACE_OPTION != "1" ]; then
  echo "Trace option can be only 0 (any trace) or 1 (shortest trace).";
  echo 
  usage;
fi 

shift $((OPTIND-1))

=end

#RUBY_SCRIPT_OPTS = RO.join " "
BIN_DIR=File.dirname(__FILE__)
OUT_DIR=File.dirname($options[:filename])

=begin

# TODO: Check Mac GUI with the new tree layout

# At the Mac GUI there'll be no ./csv2uppal because 
# everything is packaged inside the same directory
#if [ -r $(dirname "$0")/csv2uppaal ]; then
#  DIR_NAME=$(dirname "$0")/csv2uppaal;
#else
#  DIR_NAME=$(dirname "$0");
#fi


if [ "$#" -le 0 ]; then
  echo "Provide as an argument a protocol description (a .csv file).";
  usage;
  # exit;
fi
  

if [ ${1##*.} != "csv" ]; then
  echo "The file in the argument must be a .csv file.";
  usage;
  # exit;
fi

#Now we convert the csv file to xml file
if [ -r "$1" ]; then
 "$BIN_DIR/csv2xml.sh" "$1" > "${OUT_DIR}/tmp.xml"
# echo "The intermediate output has been written to tmp.xml."
else
 echo "The protocol description in .csv does not exist or cannot be read.";
 echo
 usage;
 #exit 1;
fi

=end

CSV2XML = File.join "#{BIN_DIR}", "csv2xml.sh"
TMP_XML = File.join "#{OUT_DIR}", "tmp.xml"

system "#{CSV2XML} \'#{$options[:filename]}\' > \'#{TMP_XML}\'"

=begin
# Now the ruby script should be called on tmp.xml
if [ -r "${OUT_DIR}/tmp.xml" ]; then
 ruby "${BIN_DIR}/xml2uppaal.rb" $RUBY_SCRIPT_OPTS "${OUT_DIR}/tmp.xml" "$1";
 if [ $? -ne 0 ]; then
   echo "Error translating the intermediate file to uppaal format with the ruby script";
   exit 1;
 fi
 # 'rm' can't be just after the calling of the ruby script... 
 #"$?" saves the exit status of the LAST command, so rm will blurr the ruby exit status.
 #rm tmp.xml; 

else
 echo "The intermediate file 'tmp.xml' does not exist or cannot be read.";
 echo
 exit 1;
fi
=end

unless File.exist? TMP_XML
  raise ArgumentError, "File #{TMP_XML} doesn't exist."
end

#XML2UPPAAL = File.join "#{BIN_DIR}", "xml2uppaal.rb"

#system "ruby \'#{XML2UPPAAL}\' #{RUBY_SCRIPT_OPTS} \'#{TMP_XML}\' \'#{$options[:filename]}\' "

protocol = Parser.parse(TMP_XML)
Render.renderize(protocol)

=begin
# Start of verifyta part and trace generation
OS=`uname`
LINUX_VERIFYTA=/usr/local/bin/verifyta
MAC_VERIFYTA=/Applications/verifyta

if [ "$OS" = "Darwin" ]; then
  if [ -x $MAC_VERIFYTA ]; then
   VERIFYTA=$MAC_VERIFYTA
   echo
   echo "# Runnig the UPPAAL verification engine using ${VERIFYTA}"
   echo "# This might take a while ..."
   echo "# You can verify the protocol faster if you lower the capacity of the medium." 
  fi
elif [ "$OS" = "Linux" ]; then
  if [ -x $LINUX_VERIFYTA ]; then
    VERIFYTA=$LINUX_VERIFYTA
    echo "Using ${VERIFYTA}..."
  fi
fi

if [ -z "$VERIFYTA" ]; then
  echo "Error: the script was not able to find the UPPAAL engine file verifyta.";
  echo "Check the README file in the tool distribution for info how to intall UPPAAL.";
  echo
  exit;
fi

=end

LINUX_VERIFYTA="/usr/local/bin/verifyta"
MAC_VERIFYTA="/Applications/verifyta"
LOCAL_VERIFYTA="./verifyta"

VERIFYTAS = [LINUX_VERIFYTA, MAC_VERIFYTA, LOCAL_VERIFYTA]

VERIFYTA = VERIFYTAS.find {|f| File.executable?(f) }

unless VERIFYTA
  puts <<EOS

Error: the script was not able to find the UPPAAL engine file verifyta in any of the following locations.
#{VERIFYTAS.inspect}
Check the README file in the tool distribution for info how to intall UPPAAL.
   
EOS

raise RuntimeError, "Couldn't find verifyta."

end

=begin

PROTOCOL="${1%\.*}"

if ! $EXTENSIONS; then

$VERIFYTA -Y -o 2 -t $TRACE_OPTION "${PROTOCOL}.xml" "${PROTOCOL}-overflow.q" 2> "${OUT_DIR}/tmp.trc" > "/dev/null"

 if [ $? -ne 0 ]; then
   echo
   cat  "${OUT_DIR}/tmp.trc"
   echo
   echo "See README file for futher instructions on how to install verifyta";
   echo
   exit 1;
 fi
=end

if $options[:fairness]
  %x|#{VERIFYTA} -Y -o 2 #{$options[:trace]} "#{OUT_DIR+"/"+$options[:protocol]}.xml" "#{OUT_DIR+"/"+$options[:protocol]}-overflow.q" 2> "#{OUT_DIR}/#{$options[:protocol]}-overflow.trc" > "#{OUT_DIR}/tmp_stdout.trc"|
end

puts
puts "*** BOUNDEDNESS *** "

line_no = 0
File.foreach("#{OUT_DIR}/#{$options[:protocol]}-overflow.trc") do |line|

  #  PARTICIPANT.START->PARTICIPANT.START { guard__Active__CannotComplete_p__OUTBOUND(), tau, action__Active__CannotComplete_p__OUTBOUND() }
  #  PARTICIPANT._id_PARTICIPANT_INVARIANT->PARTICIPANT._id_PARTICIPANT_INVARIANT { guard_FailingActive_Fail_p_OUTBOUND() && x <= TIRE_OUT && y >= MIN_DELAY, tau, action_FailingActive_Fail_p_OUTBOUND(), y := 0 
  #  COORDINATOR.START->COORDINATOR.START { guard__Completing__Exit_p__INBOUND(), tau, action__Completing__Exit_p__INBOUND() }


  regexp = /^\s*(\w+?)\.(\w*)->\w*\.(\w*).*guard__(\w*)__(\w*)__(OUTBOUND|INBOUND)/

#  p line
#  puts "***"
  match_data = line.match regexp
  if match_data
     line_no += 1
     all_match_string,
     role_name,
     label1,
     label2,
     state,
     action,
     out_or_in = match_data.to_a
     puts "#{line_no}. #{role_name} in state [#{state}] performs #{out_or_in.downcase} action [#{action}]"
  end

end
       
    

=begin


echo
echo "*** BOUNDEDNESS *** "
awk -F ";" 'BEGIN {i=0; print "-------------------"}   match($1,"guard")!= 0 {i=i+1;
rolename=substr($1,3,match($1,".-")-8);
action=substr($1,match($1,"guard")+6,match($1,"tau")-match($1,"guard")-10);
state=substr(action,1,match(action,"_")-1);
pos=match(action,"_")+1;
if (substr(action,length(action)-6,2)=="IN") {event="inbound action"; end=pos+7};
if (substr(action,length(action)-6,2)=="UT") {event="outbound action"; end=pos+8};
message=substr(action,pos,length(action)-end);
print i". " rolename, "in state",state, "performs", event, message}
END {if (i==0) 
{print "There is no buffer overflow, the protocol is bounded."}
else {
print "---";
print "The trace above shows that for the given capacity there is an overflow."
} }' "${OUT_DIR}/tmp.trc"

fi

if $EXTENSIONS; then

$VERIFYTA -Y -o 2 -t $TRACE_OPTION "${PROTOCOL}.xml" "${PROTOCOL}-overflow.q" 2> "${OUT_DIR}/tmp.trc" > "/dev/null"

echo
echo "*** BOUNDEDNESS (under fairness) *** "
awk -F ";" 'BEGIN {i=0; print "------------------------------------"}   match($1,"guard")!= 0 {i=i+1;
rolename=substr($1,3,match($1,"._")-3);
action=substr($1,match($1,"guard")+6,match($1,"\\(\\)")-match($1,"guard")-6);
state=substr(action,1,match(action,"_")-1);
pos=match(action,"_")+1;
if (substr(action,length(action)-6,2)=="IN") {event="inbound action"; end=pos+7};
if (substr(action,length(action)-6,2)=="UT") {event="outbound action"; end=pos+8};
message=substr(action,pos,length(action)-end);
print i". " rolename, "in state",state, "performs", event, message}
END {if (i==0)
{print "There is no buffer overflow, the protocol is bounded."}
else {
print "---";
print "The trace above shows that for the given capacity there is an overflow."
} }' "${OUT_DIR}/tmp.trc"

fi

if ! $DEBUG; then
  rm -f "${OUT_DIR}/tmp.trc" "${PROTOCOL}-overflow.q"
fi



if ! $EXTENSIONS; then

  $VERIFYTA -Y -o 2 -t $TRACE_OPTION "${PROTOCOL}.xml" "${PROTOCOL}-invalid.q" 2> "${OUT_DIR}/tmp1.trc" > "/dev/null"
  echo
  echo "*** CORRECTNESS *** "
  awk -F ";" 'BEGIN {i=0; print "-------------------"}   match($1,"guard")!= 0 {i=i+1;
rolename=substr($1,3,match($1,".-")-8);action=substr($1,match($1,"guard")+6,match($1,"tau")-match($1,"guard")-10);
state=substr(action,1,match(action,"_")-1);
pos=match(action,"_")+1;
if (substr(action,length(action)-6,2)=="IN") {event="inbound action"; end=pos+7};
if (substr(action,length(action)-6,2)=="UT") {event="outbound action"; end=pos+8};
message=substr(action,pos,length(action)-end);
print i". " rolename, "in state",state, "performs", event, message}
  END {if (i==0) {
  print "There are no invalid states reachable in the protocol."
  print "Note that if there is a buffer overflow, then there are"
  print "no invalid states only up to the given buffer capacity."
  } else
  { print "---"; print "The trace above shows that an invalid state can be reached."
  }}' "${OUT_DIR}/tmp1.trc"

fi

if ! $DEBUG; then
  rm -f "${OUT_DIR}/tmp1.trc" ${PROTOCOL}-invalid.q 
fi

if ! $EXTENSIONS; then
$VERIFYTA -Y -o 2 -t $TRACE_OPTION "${PROTOCOL}.xml" "${PROTOCOL}-ended.q" 2> "${OUT_DIR}/tmp2.trc" > "/dev/null"
echo
echo "*** TERMINATION *** "
awk -F ";" 'BEGIN {i=0; print "-------------------"}   match($1,"guard")!= 0 {i=i+1;
rolename=substr($1,3,match($1,".-")-8);action=substr($1,match($1,"guard")+6,match($1,"tau")-match($1,"guard")-10);
state=substr(action,1,match(action,"_")-1);
pos=match(action,"_")+1;
if (substr(action,length(action)-6,2)=="IN") {event="inbound action"; end=pos+7};
if (substr(action,length(action)-6,2)=="UT") {event="outbound action"; end=pos+8};
message=substr(action,pos,length(action)-end);
print i". " rolename, "in state",state, "performs", event, message}
END {if (i==0) {
print "The roles cannot enter their Ended states within the given medium capacity."
print "Note that if there is a buffer overflow you may"
print "want to increase the capacity of the medium and try again."
} else 
{ print "---"; print "The above trace shows how the roles can reach their ended states."
}
}' "${OUT_DIR}/tmp2.trc"

fi


if $EXTENSIONS; then
$VERIFYTA -Y -o 2 -t $TRACE_OPTION "${PROTOCOL}.xml" "${PROTOCOL}-ended.q" 2> "${OUT_DIR}/tmp2.trc" > "/dev/null"
echo
echo "*** TERMINATION (under fairness) *** "
awk -F ";" 'BEGIN {i=0; print "------------------------------------"}   match($1,"guard")!= 0 {i=i+1;
rolename=substr($1,3,match($1,"._")-3);
action=substr($1,match($1,"guard")+6,match($1,"\\(\\)")-match($1,"guard")-6);
state=substr(action,1,match(action,"_")-1);
pos=match(action,"_")+1;
if (substr(action,length(action)-6,2)=="IN") {event="inbound action"; end=pos+7};
if (substr(action,length(action)-6,2)=="UT") {event="outbound action"; end=pos+8};
message=substr(action,pos,length(action)-end);
print i". " rolename, "in state",state, "performs", event, message}
END {if (i==0) {
print "The roles will eventually reach their Ended states."
print "Note that if there is a buffer overflow you may"
print "want to increase the capacity of the medium and try again."
} else
{ print "---"; print "The above trace shows a loop or it ends in a deadlock\nsuch that the roles do not reach their ended states."
}
}' "${OUT_DIR}/tmp2.trc"

fi

if ! $DEBUG; then 
  rm -f "${OUT_DIR}/tmp2.trc" "${PROTOCOL}-ended.q"
fi

if ! $EXTENSIONS; then

  $VERIFYTA -Y -o 2 -t $TRACE_OPTION "${PROTOCOL}.xml" "${PROTOCOL}-deadlock.q" 2> "${OUT_DIR}/tmp3.trc" > "/dev/null"
  echo
  echo "*** DEADLOCK-FREENESS *** "
  awk -F ";" 'BEGIN {i=0; print "-------------------------"}   match($1,"guard")!= 0 {i=i+1;
rolename=substr($1,3,match($1,".-")-8);action=substr($1,match($1,"guard")+6,match($1,"tau")-match($1,"guard")-10);
state=substr(action,1,match(action,"_")-1);
pos=match(action,"_")+1;
if (substr(action,length(action)-6,2)=="IN") {event="inbound action"; end=pos+7};
if (substr(action,length(action)-6,2)=="UT") {event="outbound action"; end=pos+8};
message=substr(action,pos,length(action)-end);
print i". " rolename, "in state",state, "performs", event, message}
  END {if (i==0) {
  print "There was no deadlock found in the protocol."
  print "Note that if there is a buffer overflow, then there are"
  print "no deadlocks only up to the given buffer capacity."
  } else {
  print "---"; print "The above trace leads to a deadlock."
  }}' "${OUT_DIR}/tmp3.trc"

fi

if ! $DEBUG; then
  rm -f "${OUT_DIR}/tmp3.trc" "${PROTOCOL}-deadlock.q"
fi

echo
echo "# More detailed verification can be done directly in the tool UPPAAL."
echo "# To do so, run UPPAAL and open the file" ${1%\.*}.xml 
echo "# together with the query" ${1%\.*}.q "and then simulate/verify."
echo

=end


