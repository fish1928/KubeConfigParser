require 'singleton'

class ParameterCenter
  include Singleton

  False = false
  True = true

  attr_reader :registered_item_map

  def initialize
    @registered_item_map = {}
  end

  def register_item(item)
    item.keys.each do |key|
      @registered_item_map[key] = item[key]
    end
  end

  def parse(str)
    eval(str)
  end

  def method_missing(method_name_sym, *args)
    target = @registered_item_map[method_name_sym]

    if args.empty?
      return target
    else
      return target.new(*args)
    end

  end
end
