#!/usr/bin/env ruby

libdir = File.join(File.dirname(__FILE__), '..', 'lib')

$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include? libdir

require "optparse"
require 'rexml/document'
require "helper"
require "protocol_object"
require "parser"
require "render"

include REXML

$options = {}

opts = OptionParser.new do |opts|
  opts.banner = "Usage: trace.sh [options]"

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
    $options[:capacity] = c.to_i
  end
  
  opts.on("-t", "--trace VALUE", ["0", "1"], "Trace: 0 for any trace, 1 for shortest trace") do |t|
    $options[:trace] = t.to_i
  end
  
  opts.on("-i", "--ignore", "All messages will be treated as ordered") do 
    $options[:ignore] = true
  end
  
  opts.on("-f", "--force_timed", "Enable timed extension") do 
    $options[:timed] = true
  end
  
  opts.on("-x", "--min-delay VALUE", Integer, "Sets MIN_DELAY constant value") do |x|
    $options[:min_delay] = x.to_i
  end

  opts.on("-y", "--tire-out VALUE", Integer, "Sets TIRE_OUT constant value") do |t|
    $options[:tire_out] = t.to_i
  end
  
end.parse!

ARGV.each do |arg|
  case arg
    when /\.xml/
    if $options[:filename].nil?
      $options[:filename] = arg
    else
      raise ArgumentError, "More than one .xml file given at commandline."
    end
    
    when /\.csv/
    if $options[:protocol].nil?
      $options[:protocol] = File.basename(arg, ".csv")
    else
      raise ArgumentError, "More than one .csv file given at commandline."
    end
  end
end

filename = $options[:filename] || "inputfile.xml" # If no filename given, default is inputfile.xml

protocol = Parser.parse(filename)
Render.renderize(protocol)
