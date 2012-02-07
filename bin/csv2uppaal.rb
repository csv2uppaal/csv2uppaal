#!/usr/bin/env ruby
# Takes as argument *.csv protocol description file (exported using save as from
# OpenOffice using ; as delimiers and outputs *.xml and *.q files that can
# be opened in UPPAAL; then it tries to call the command line verifyta
# (UPPAAL engine) if possible and outputs a possible error trace in text format.
# Make sure that this file and csv2xml.sh are executable via chmod +x filename

require "optparse"
require 'rexml/document'

rootdir = File.join File.dirname(__FILE__), '..'
libdir = File.join rootdir, 'lib'

load File.join rootdir, "CONFIG"

$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include? libdir

require "c2u_optparse"
require "helper"
require "protocol_object"
require "parser"
require "render"
require "verifier"

include REXML

BIN_DIR=File.dirname(__FILE__)
OUT_DIR=File.dirname(Opt.filename)

# TODO: Check Mac GUI with the new tree layout

CSV2XML = File.join "#{BIN_DIR}", "csv2xml.rb"
TMP_XML = File.join "#{OUT_DIR}", "tmp.xml"

cmd = %|ruby #{CSV2XML.to_syspath} #{Opt.filename.to_syspath} > #{TMP_XML.to_syspath}|
%x|#{cmd}|

unless File.exist? TMP_XML
  raise ArgumentError, "File #{TMP_XML} doesn't exist."
end

protocol = Parser.parse(TMP_XML)
Render.renderize(protocol)

VERIFYTA = VERIFYTAS.find {|f| File.executable?(f) }

unless VERIFYTA
  puts "Error: the script was not able to find the UPPAAL engine file verifyta in any of the following locations."
  puts "#{VERIFYTAS.inspect}"
  puts "Check the README file in the tool distribution for info how to intall UPPAAL."

  raise RuntimeError, "Couldn't find verifyta."
end

constraints = 
  Opt.fairness? ? 
    [:boundedness_under_fairness, :termination_under_fairness] :
    [:boundedness, :correctness, :termination, :deadlock_freeness]

constraints.each do |constraint|
  puts Verifier.new(constraint).verify 
end

puts Verifier.footer
