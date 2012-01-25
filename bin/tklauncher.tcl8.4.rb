#!/usr/bin/env ruby

require 'tk'

root = TkRoot.new { title "csv2uppaal"}

content = TkFrame.new(root) {padx "3"; pady "12"; }.grid( 'columnspan'=>4, :sticky => 'nsew')

TkGrid.columnconfigure root, 0, :weight => 1; TkGrid.rowconfigure root, 0, :weight => 1
TkGrid.columnconfigure content, 3, :weight => 1; TkGrid.rowconfigure content, 3, :weight => 1

f1 = TkFrame.new(content) do
  grid('stick'=>'wn', 'row'=>0, 'column'=>0, 'padx'=>5, 'pady'=>5)
end

f2 = TkFrame.new(content) do
  grid('stick'=>'wn', 'row'=>0, 'column'=>1, 'padx'=>5, 'pady'=>5)
end

f_radio = TkFrame.new(content) do
  grid('stick'=>'w', 'row'=>0, 'column'=>2, 'padx'=>5, 'pady'=>5)
end

f3 = TkFrame.new(content) do
  grid('stick'=>'wen', 'row'=>1, 'column'=>0, 'columnspan'=>4, 'padx'=>5, 'pady'=>5)
end

f4 = TkFrame.new(content) do
  grid('stick'=>'w', 'row'=>2, 'column'=>0,  'columnspan'=>3, 'padx'=>5, 'pady'=>5)
end

f5 = TkFrame.new(content) do
  borderwidth 3
  relief 'sunken'
  grid('stick'=>'wnse', 'row'=>3, 'column'=>0, 'columnspan'=>4 , 'padx'=>5, 'pady'=>5)
end

TkGrid.columnconfigure f5, 0, :weight => 1; TkGrid.rowconfigure f5, 0, :weight => 1

$ochk = TkVariable.new("")
OChk = TkCheckButton.new(f1) do
  text "Multiple Channel Optimization" # (-o)
  onvalue "-o"
  offvalue ""
  variable $ochk
  grid('row'=>0, 'column'=>0, 'sticky'=>'w')
end

$tchk = TkVariable.new("")
TChk = TkCheckButton.new(f1) do
  text "Shortest Trace" #  (-t 1)
  onvalue "-t 1"
  offvalue ""
  variable $tchk
  grid('row'=>1, 'column'=>0, 'sticky'=>'w')
end

$ichk = TkVariable.new("")
IChk = TkCheckButton.new(f1) do
  text "Ignore Unordered Messages" # (-i)
  onvalue "-i"
  offvalue ""
  variable $ichk
  grid('row'=>2, 'column'=>0, 'sticky'=>'w')
end

$fchk = TkVariable.new("")
FChk = TkCheckButton.new(f1) do
  text "Termination under fairness" # (-f)
  onvalue "-f"
  offvalue ""
  variable $fchk
  grid('row'=>3, 'column'=>0, 'sticky'=>'w')
end

$q = TkVariable.new("FROM FILE")

['FROM FILE', 'SET', 'BAG', 'FIFO', 'LOSSY', 'STUTT'].each do |name| 
  TkRadioButton.new(f_radio) do
    text name
    value name
    variable $q
    anchor 'w'
    grid('stick' => 'w')
  end
end

# Medium capacity entry box

TkLabel.new(f2) do
  text 'Medium Capacity'
  grid('row'=>1, 'column'=>1, 'sticky'=>'w')
end

$c = TkVariable.new("")

CEntry = TkEntry.new(f2) do
  textvariable $c
  width 3
  grid('row'=>1, 'column'=>0, 'sticky'=>'e')
end

# MIN_DELAY entry box

TkLabel.new(f2) do
  text 'MIN_DELAY'
  grid('row'=>2, 'column'=>1, 'sticky'=>'w')
end

$x = TkVariable.new("")

XEntry = TkEntry.new(f2) do
  textvariable $x
  width 3
  grid( 'row'=>2, 'column'=>0, 'sticky'=>'e')
end


# TIRE_OUT entry box


TkLabel.new(f2) do
  text 'TIRE_OUT'
  grid('row'=>3, 'column'=>1, 'sticky'=>'w')
end

$y = TkVariable.new("")

YEntry = TkEntry.new(f2) do
  textvariable $y
  width 3
  grid('row'=>3, 'column'=>0, 'sticky'=>'e')
end

$file_selected = TkVariable.new

TkGrid.columnconfigure(f3, 0, :weight => 1)

file_entry = TkEntry.new(f3) do
  textvariable $file_selected
  grid('stick'=>'we', 'row'=>'0', 'column'=>'0')
end

SelectFileBtn = TkButton.new(f4) do
  text 'Select Protocol (*.csv)'
  command { $file_selected.value = Tk.getOpenFile}
  grid('sticky'=>'w', 'column'=>0, 'row'=>0, 'padx'=>'0 5')
  
end

t1 = s1 = nil

# The button callback

cmd_line = Proc.new do
  q_value = ($q.value == "FROM FILE" ? "" : "-m #{$q.value}")
  c_value = ( ($c.value =~ /^ *\d+ *$/) ? "-c #{$c.value.to_i}" : "")
  x_value = ( ($x.value =~ /^ *\d+ *$/) ? "-x #{$x.value.to_i}" : "") 
  y_value = ( ($y.value =~ /^ *\d+ *$/) ? "-y #{$y.value.to_i}" : "") 
  
  clstr = "./csv2uppaal.sh " +
  [$ochk, $tchk, $ichk, $fchk].map {|c| c.value }.join(" ") + 
    " #{q_value}" + 
    " #{c_value}" +
    " #{x_value}" +
    " #{y_value}" +
    " #{$file_selected.value.empty? ? "" : "'" + $file_selected.value + "'"}"
    
  cmd_str = clstr+" 2>&1"
  t1.delete '0.0', 'end'

  tool_output=""

  t1.insert 'end', "Verifying..."

  $progress_thread = Thread.new do 
    loop do
      t1.insert 'end', '.'
      sleep 0.2
    end
  end

  $cmd_line_thread = Thread.new do
    tool_output = %x{#{cmd_str}}
    Thread.kill $progress_thread
    t1.insert 'end', "\n#{tool_output}"
  end
  
end

SubmitButton = TkButton.new(f4) do
  text 'Verify Protocol'
  command cmd_line
  grid('sticky'=>'w', 'column'=>1, 'row'=>'0', 'padx'=>'15 0')
end



$report_output = TkVariable.new

t1 = TkText.new(f5) do
  height 20
  setgrid 1
  grid('stick'=>'wnse', 'column'=>0, 'row'=>'0')
end

s1 = TkScrollbar.new(f5) do
  command proc { |*args| t1.yview *args }
  grid('stick'=>'wns', 'column'=>1, 'row'=>'0')
end

t1.yscrollcommand(proc { |first,last| s1.set(first,last) })

Tk.mainloop
