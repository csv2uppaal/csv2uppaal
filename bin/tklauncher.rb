#!/usr/bin/env ruby

require 'tk'

if Tk::TCL_VERSION == "8.4"
  load './csv2uppaal/tklauncher.tcl8.4.rb'
else
  load './csv2uppaal/tklauncher.tcl8.5.rb'
end
