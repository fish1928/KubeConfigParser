require_relative 'expression'

class Explainer

  @expression_map = {}

  class << self
    attr_accessor :expression_map
  end

  def self.inherited(sub_klass)
    sub_klass.class_eval do
      def self.register_expression(reg_exp)
        Explainer.expression_map[reg_exp] = self
      end
    end
  end

  def initialize(paragraph)
    @paragraph = paragraph
  end

  def explain(lines)
    new_lines = []

    while not lines.empty?
      line = lines[0]

      matched_explainer_expression = self.class.expression_map.keys.find do |key|
        line.match(key)
      end

      if matched_explainer_expression
        matched_explainer = self.class.expression_map[matched_explainer_expression]
        lines = matched_explainer.handle(lines)
      else
        new_lines << lines.shift
      end
    end

    return new_lines
  end
end

class GlobalSetter < Explainer
  START_REG = /^\{% set (.*?) %\}/
  register_expression START_REG

  def self.handle(paragraph_lines)
    line = paragraph_lines.shift
    content = line.match(START_REG)[1].gsub(' ','')
    target, expression_str = content.split('=')
    value = ExpressionPipe.handle(expression_str)
    ParameterCenter.instance.register_item({target.to_sym => value})
    return paragraph_lines
  end
end

class SimpleParser < Explainer
  START_REG = /\{\{(.*?)\}\}/
  register_expression START_REG

  def self.handle(paragraph_lines)
    line = paragraph_lines.shift
    content = line.match(START_REG)[1]
    value = ExpressionPipe.handle(content)

    element = '{{' + content + '}}'
    start_index = line.index(element)
    end_index = start_index + element.size - 1
    line[start_index..end_index] = value.to_s
    paragraph_lines.insert(0, line)
  end
end

class IfDefinedBlocker < Explainer
  START_REG = /\{% if (.*?) is defined -%\}/
  END_REG = /\{% endif -%\}/

  register_expression self::START_REG

  def self.handle(paragraph_lines)

    block_lines = []
    while not (line = paragraph_lines.shift).match(self::END_REG)
      block_lines << line
    end
    block_lines << line

    condition_line = block_lines[0]
    content = condition_line.match(self::START_REG)[1]

    begin
      value = ExpressionPipe.handle(content)
      raise NoMethodError if value.nil?

      block_inner_lines = block_lines[1..-2]
      paragraph_lines = block_inner_lines + paragraph_lines
    rescue NoMethodError
      # should be but no log currently
    end

    return paragraph_lines
  end

end


class IfBlocker < IfDefinedBlocker

  START_REG = /\{% if (.*?) %\}/
  END_REG = /\{% endif %\}/
  register_expression self::START_REG

end

