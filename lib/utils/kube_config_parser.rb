require 'yaml'

module ::YAML
  def self.kube_load(all_str)
    all_str.split("---\n").reject(&:empty?).map do |paragraph|
      YAML.load(paragraph)
    end
  end
end

module ParserModule
  class SimpleHash
    def initialize(hash)
      @hash = hash
    end

    def method_missing(method_name_sym)
      result = @hash[method_name_sym.to_s] || @hash[method_name_sym]
      return nil if result.nil?
      SimpleHash.new(result)
    end

    def inspect
      @hash.inspect
    end

    def to_s
      @hash.to_s
    end
  end

  class EnvParser


    False = false
    True = true

    def initialize(input_table, ifelse_stack)
      @input_table = input_table
      @variable_table = {}
      @ifelse_stack = ifelse_stack
    end

    def ifelse_stack
      @ifelse_stack
    end

    def update(line)
      command = line.gsub(/\s?\|\s?/, ' || ').gsub(/set (.*?) =/, 'set[\'\1\'] =')
      eval(command)
    end

    def set
      @variable_table
    end

    def item
      return SimpleHash.new(@input_table)
    end

    def default(value_str)
      value_str
    end

    def method_missing(method_name_sym)
      @variable_table[method_name_sym.to_s] || @variable_table[method_name_sym]
    end

    def echo(str)
      command = '"' + str + '"'
      #puts command
      eval(command)
    end

  end

  class IfElseStack
    def initialize
      @seq = []
    end

    def push(condition, str)
      @seq.push([condition, str])
    end

    def top
      condition, str = @seq.delete_at(0)
      is_ruby_value = str.match(/#\{(.*?)\}/)
      str = @env_parser.instance_eval(is_ruby_value[1]) if is_ruby_value
      @env_parser.instance_eval(condition) ? str : nil
    end

    def set_env_parser(env_parser)
      @env_parser = env_parser
    end

  end

  class RubyStrParser
    def self.parse(str)
      str.gsub(/\{\{(.*?)\}\}/, '#{\1}').gsub(/\s?\|\s?/, ' || ').gsub('"', '\"')
    end
  end

  class KubeConfigParser
    def self.parse(template_path, variable_path)
      ifelse_stack = IfElseStack.new

      yml_content = File.open(template_path).read.each_line.map(&:chomp).to_a
      env_lines = []
      normal_lines = []

      in_if_else_block = false
      if_else_matched_condition = nil
      if_else_matched_lines = []

      yml_content.each do |line|
        match_result = line.match(/^\{\% (set (.*?)) \%\}$/)
        if match_result
          env_lines << match_result[1]
        else
          if in_if_else_block
            match_if_else_end = line.match(/\{\% endif -?\%\}/)
            if match_if_else_end
              ifelse_stack.push(if_else_matched_condition, if_else_matched_lines.join('\n'))
              normal_lines << '#{ifelse_stack.top}'
              in_if_else_block = false
              if_else_matched_condition = nil
              if_else_matched_lines = []
            else
              if line.match(/\{\{.*?\}\}/)
                if_else_matched_lines << RubyStrParser.parse(line)
              else
                if_else_matched_lines << line
              end
            end
          else  # not in if else block
            match_if_else_start = line.match(/\{\% if (.*?) (is defined )?-?\%\}/)
            if match_if_else_start
              in_if_else_block = true
              if_else_matched_condition = match_if_else_start[1]
            else
              normal_lines << line
            end
          end
        end
      end

      var_table = YAML.load(File.open(variable_path).read)

      normal_yml_content = normal_lines.join("\n")
      normal_yml_content

      parser = EnvParser.new(var_table, ifelse_stack)
      ifelse_stack.set_env_parser(parser)

      env_lines.each do |first_line|
        parser.update(first_line)
      end

      ruby_style_content = RubyStrParser.parse(normal_yml_content)
      parser.echo(ruby_style_content)
    end
  end
end
