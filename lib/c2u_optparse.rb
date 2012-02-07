require 'ostruct'
require 'questionize'

CSV2UPPAAL_VERSION = '2.2' 

raise "Opt constant already defined" if defined? Opt

# OpenStruct.send(:include, Questionize)

class OpenStruct; include Questionize; end

Opt = OpenStruct.new

# Some defaults
Opt.trace = "-t 0"

opts = OptionParser.new do |opts|
  opts.banner = "csv2uppaal #{CSV2UPPAAL_VERSION} - csv to uppaal conversion tool\nUsage: csv2uppaal [options] [filename.csv]"
  opts.version = CSV2UPPAAL_VERSION

  opts.on("-o", 
          "--[no-]optimize", 
          "Sets multiple channels optimization on.") do |o|
    Opt.optimize = o
    Opt.questionize_method :optimize
  end
  
  ms = [:Set, :Bag, :Fifo, :Stutt, :Lossy]
  m_all = ms + ms.map{|m| m.to_s.upcase} + ms.map{|m| m.to_s.downcase}
  opts.on("-m", "--medium MEDIUM", m_all,
                "Sets medium type (set, bag, fifo, lossy, stutt)") do |m|
    Opt.medium = m.to_s.upcase
  end
  
  opts.on("-c", "--capacity VALUE", Integer, "Sets channel capacity") do |c|
    Opt.capacity = c
  end
  
  opts.on("-t", "--trace VALUE", ["0", "1"], Integer, "Trace: 0 for any trace, 1 for shortest trace") do |t|
    Opt.trace = "-t #{t}"
  end
  
  opts.on("-i", "--ignore", "All messages treated as ordered (ignore unordered flag)") do 
    Opt.ignore = true
    Opt.questionize_method :ignore
  end
  
  opts.on("-f", "--fairness", "Termination under fairness (all executions eventually terminate)" ) do 
    Opt.timed = Opt.fairness = true
    Opt.questionize_method :fairness
    Opt.questionize_method :timed
  end
  
  opts.on("-x", "--min-delay VALUE", Integer, "Sets MIN_DELAY constant value") do |x|
    Opt.min_delay = x
  end

  opts.on("-y", "--tire-out VALUE", Integer, "Sets TIRE_OUT constant value") do |y|
    Opt.tire_out = y
  end

  opts.separator ""

  opts.on("-d", "--debug", "For debug puposes don't remove temporary files") do |d|
    Opt.debug = true
    Opt.questionize_method :debug
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
    if arg =~ /.+\.csv$/
      unless Opt.protocol
        Opt.filename = arg
        Opt.protocol = File.basename(arg, ".csv")
      else
        raise ArgumentError, "More than one .csv file given at commandline."
      end
    else 
      raise ArgumentError, "Invalid FileType. Only .csv files accepted."
    end
  end

  unless Opt.filename
    raise ArgumentError, "File missing."      
    unless File.exist? Opt.filename
      raise ArgumentError, "File #{Opt.filename} doesn't exist."      
    end
  end

rescue => e
  puts "Error: #{e.message} [#{e.class}]"
  puts opts.help
  exit 1
end

