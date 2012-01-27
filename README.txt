************** 
csv2uppaal 1.1 - USERS GUIDE 
**************


A. BEFORE RUNNING THE TOOL
--------------------------
The tool chain relies on bash, awk and ruby. It was developed 
and tested under Ubuntu GNU/Linux and Mac OS X. It can be run also 
on MS Windows by installing these tools separately (see below), or 
by using cygwin (recommended). A limited testing was done Win-Bash 
that seems smaller and less 'intrusive' than cygwin.

Resources for MS Windows:
[Ruby]: http://rubyinstaller.org/
[CygWin]: http://www.cygwin.com/
[Win-Bash]: http://sourceforge.net/projects/win-bash/files/shell-complete/latest/

We provide also a graphical GUI interface on top of the command line tool. 
The GUI comes in two versions Tk and RubyCooca. More details 
on how to run the GUI is given in README-GUI.txt (recommended for all
Mac and Linux users).

IMPORTANT: To run the protocol verification, the command line tool 
verifyta coming with the distribution of UPPAAL is required,
as described in part B below. 

B. UPPAAL BACK END
------------------
To run the command line verification, the user needs to install
UPPAAL command line tool called "verifyta" that can be found in
the standard distribution package (www.uppaal.org). Note that the
tool is free only for noncommercial applications; see more at:
http://www.it.uu.se/research/group/darts/uppaal/download.shtml

IMPORTANT: If you are running 64 bit versions of linux or mac, download 
and install the 64 bit development version of UPPAAL verifyta.

On mac, copy (drag and drop) the file verifyta into the directory:
/Applications/

On linux, copy verifyta into the directory (sudo cp verifyta /usr/local/bin):
/usr/local/bin/

Then csv2uppaal will be able to locate verifyta automatically.
If you prefer to place the verifyta in other directory, you need 
to modify the path in the script csv2uppaal.sh manually.

TROUBLE-SHOOTING:

If you try to run the tool on a 64-bit linux using the 32-bit version 
of verifyta it will probably not run and you will get the following
message:

verifyta: relocation error: /lib32/libresolv.so.2: symbol strlen, version GLIBC_2.0 not defined in file libc.so.6 with link time reference

Should this happen, download the 64 bit development version and try again.


C. PROTOCOLS AS CSV FILES 
-------------------------
Protocols that the csv2uppaal tool accepts can be created in
in OpenOffice (recommended application) and saved as .csv file
with ";" as the field separator. Examples of .csv files are included
in the distribution, including a general Template.csv. The
sheets contain the keywords PROTOCOL, ROLE, STATES, IN, IN*, OUT, OUT*
and Invalid.

PROTOCOL is followed by the name of the protocol, type of medium and capacity

ROLE is followed by the name of the role

STATES is followed by an empty cell and then a list of all states for
       the particular role; some state names may end with *, which means
       that they are interpreted as Ended states

IN is followed by a name of a message and stands for inbound event

OUT is followed by a name of a message and stands for outbound event

IN* and OUT* has the same meaning as IN and OUT but moreover signal
             that the messages are unordered (for the use with abstractions)

Invalid is a special keyword representing the invalid state

Each cells in a column named by a state and a row named by a message
describes a transition of the protocol. Such cell always contains 
two strings separated by comma. For inbound messages the string before
the comma represents the message that is sent and the string after comma
is the name of the new state. For outbound events the string before comma
is always empty and the string after comma represents new state. 

We recommend the users to consult the simple example STP.csv that is self-explanatory.


D. USING THE TOOL 
-----------------
The tool for a protocol like STP is run by unzipping the archive,
opening a terminal and entering the directory where the tool
is located. The tool is then run by the command:

./csv2uppaal.sh STP.csv

If you are running Mac or Linux, we recommend that you use the
GUI for verifying protocols as described in README-GUI.txt.

The following switches are available for changing various parameters
of the protocol (if the same parameters are declared also in .csv file
that the switches override these settings):

csv2uppaal.sh <filename.csv> (verify the given protocol)
csv2uppaal.sh -o (multiple channel optimization)
csv2uppaal.sh -t 0 (default, finds some error trace)
csv2uppaal.sh -t 1 (finds the shortest error trace)
csv2uppaal.sh -m [set|bag|fifo|lossy|stutt] (override the default medium)
csv2uppaal.sh -c capacity (sets the channel capacity to a positive integer)
csv2uppaal.sh -i all messages treated as ordered (ignore unordered flag) 
csv2uppaal.sh -d (do not delete the temporary files, debugging mode)
csv2uppaal.sh -f termination with fairness (all executions successfully end)
csv2uppaal.sh -x <value> sets MIN_DELAY constant for the fairness model
csv2uppaal.sh -y <value> sets TIRE_OUT constant for the fairness model
csv2uppaal.sh -h (shows this help)


