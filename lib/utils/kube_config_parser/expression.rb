require_relative 'parameter_center'

class ExpressionPipe

  def self.handle(expression_str)
    expressions = expression_str.split('|').map {|expression_str| Expression.generate(expression_str) }
    result = expressions.inject(nil){ |param, expression| expression.handle(param) }
    return result
  end

end

class Expression
  @expression_map  ={}

  class << self
    attr_accessor :expression_map
  end

  def self.inherited(sub_klass)
    sub_klass.class_eval do
      def self.register_method(method_name)
        Expression.expression_map[method_name] = self
      end
    end
  end


  def self.generate(expression_str)
    result = ParameterCenter.instance.parse(expression_str)
    result = NormalString.new(result) if not result.is_a? Expression

    return result
  end

  def initialize(*parameters)
    @parameters = parameters
  end


  def handle(previous_value)
    raise NotImplementedError
  end

end


class B64encoder < Expression
  register_method :b64encode

  def handle(_)
    return @parameters.first
  end

end

class DefaultString < Expression
  register_method :default

  def handle(previous_value)
    previous_value || @parameters.first
  end
end

class NormalString < Expression
  def handle(_)
    return @parameters.first
  end
end