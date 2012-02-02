#!/bin/bash
# Translates csv files exported from Open Office using ; as delimiter to xml

awk -F ";" ' function strip(s)
     { return substr(s,2,length(s)-2)}
strip($1)=="PROTOCOL" {print "<protocol name="$2,"medium="$3,"capacity=\""$4"\">"}' "$1"

awk -F ";" 'function strip(s){ return substr(s,2,length(s)-2)}
 {if (strip($1)=="IN" || strip($1)=="OUT") {print strip($2)}}
 {if (strip($1)=="IN*" || strip($1)=="OUT*") {print strip($2)"*"}}' "$1" > tmp1.xml


#removes duplicates of messages
sort tmp1.xml | uniq > tmp2.xml
rm tmp1.xml
awk 'BEGIN {print "\t<messages>"; last="xxxxx"}
 { if ("*"== substr($1,length($1),1)) 
{print "\t\t<message type=\"unordered\">"substr($1,1,length($1)-1)"</message>";
  last="xxxxx";}
  else {if (last != "xxxxx") {print "\t\t<message>"last"</message>";} 
        last=$1;}}
  END {if (last != "xxxxx") {print "\t\t<message>"last"</message>";}
       print "\t</messages>"}' tmp2.xml
echo
rm tmp2.xml

awk -F ";" '
  function strip(s) 
     { return substr(s,2,length(s)-2)}
  function rulein(state, message, action) 
     { print "\t<rule id=\""state"__"message"__INBOUND\">";
       print "\t\t<pre>";
       print "\t\t\t<current_state>"state"</current_state>";
       print "\t\t\t<received_message>"message"</received_message>";
       print "\t\t</pre>";
       print "\t\t<post>";
       pos=match(action,","); 
       if (pos>1) { print "\t\t\t<send_message>"substr(action,1,pos-1)"</send_message>"}
       print "\t\t\t<next_state>"substr(action,pos+1,length(action))"</next_state>"
       print "\t\t</post>";
       print "\t</rule>\n"  }
  function ruleout(state, message, action) 
     { print "\t<rule id=\""state"__"message"__OUTBOUND\">";
       print "\t\t<pre>";
       print "\t\t\t<current_state>"state"</current_state>";
       print "\t\t</pre>";
       print "\t\t<post>";
       pos=match(action,","); 
       print "\t\t\t<send_message>"message"</send_message>"
       print "\t\t\t<next_state>"substr(action,pos+1,length(action))"</next_state>"
       print "\t\t</post>";
       print "\t</rule>\n"  }
  BEGIN {rolename="NONE"}
  strip($1)=="ROLE" { if (rolename != strip($2) && rolename !="NONE") {print "</role>\n"};
                      print "<role name=\""strip($2)"\">\n\t<states>"; rolename=strip($2)
                    } 
  strip($1)=="STATES" { print "\t\t<state type=\"initial\">"strip($3)"</state>";
                        states[3]=strip($3);
                        for(i=4;i<=NF;i++) {
                          if (strip($i) != "") {
                               finaltag="";statename=strip($i);
                               if (substr(strip($i),length($i)-2,1) =="*")
                                 {finaltag=" type=\"final\"";
                                  statename=substr(strip($i),1,length($i)-3)}
                           print "\t\t<state"finaltag">"statename"</state>";}
                                            states[i]=statename; 
                                           }; 
                        print "\t\t<state>Invalid</state>";
                        print "\t</states>"
                      }
  (strip($1)=="IN" || strip($1)=="IN*") { for(i=3;i<=NF;i++) { if (strip($i) != "") 
                                     { rulein(states[i],strip($2),strip($i))}}
                  } 
  (strip($1)=="OUT" || strip($1)=="OUT*") { for(i=3;i<=NF;i++) { if (strip($i) != "") 
                                     { ruleout(states[i],strip($2),strip($i))}}
                  } 
  END {print "</role>\n</protocol>"}
' "$1"


