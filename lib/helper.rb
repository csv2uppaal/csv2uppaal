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
