#!/usr/bin/env ruby

require 'tk'

libdir = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include? libdir

require 'helper' 

BIN_DIR = File.dirname(__FILE__) # this file is on bin

if Tk::TCL_VERSION == "8.4"
  load File.join BIN_DIR, "tklauncher.tcl8.4.rb"
else
  load File.join BIN_DIR, "tklauncher.tcl8.5.rb" 
end
