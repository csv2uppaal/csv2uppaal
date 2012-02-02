module Questionize
  def singleton
    class << self; self; end
  end

  def questionize_method(method_name)
    singleton.send(:alias_method, "#{method_name}?", "#{method_name}")
  end
end
