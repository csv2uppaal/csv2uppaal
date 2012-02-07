require 'pathname'

class XMLError < StandardError; end

module SUHelperMethods
  def get_name_of(from)
    case from
      when String
        from
      when Element
        from.attribute("name").to_s
      else
        nil
    end
  end

  UPPAAL_XML_HEADER = <<heredoc
<?xml version="1.0" encoding="utf-8"?><!DOCTYPE nta PUBLIC '-//Uppaal Team//DTD Flat System 1.1//EN' 'http://www.it.uu.se/research/group/darts/uppaal/flat-1_1.dtd'>
<nta>
heredoc

  UPPAAL_XML_FOOTER = <<heredoc
</nta>
heredoc


end

class Symbol
  def <=>(other)
    if other.respond_to? :to_s
      self.to_s <=> other.to_s
    else
      raise ArgumentError, "comparison of #{self.class} with #{other} failed"
    end
  end
end

class String
  def double_quoted
    m = self.match /^["']*(.*?)["']*$/
    %|"#{m[1]}"|
  end

  def unquoted
    m = self.match /^["']*(.*?)["']*$/
    m[1]
  end

  if File::ALT_SEPARATOR
    def to_syspath
      s = self.gsub File::SEPARATOR, File::ALT_SEPARATOR
      Pathname.new s.double_quoted
    end
  else
    def to_syspath
      s = self.gsub "\\", "/" 
      Pathname.new s.double_quoted
    end
  end

  def to_rbpath
    s = self.gsub "\\", "/"
    Pathname.new s.double_quoted
  end
end