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

    def initialize(input_table)
      @input_table = input_table
      @variable_table = {}
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

  class RubyStrParser
    def self.parse(str)
      str.gsub(/\{\{(.*?)\}\}/, '#{\1}').gsub(/\s?\|\s?/, ' || ').gsub('"', '\"')
    end
  end

  class KubeConfigParser
    def self.parse(template_path, variable_path)
      yml_content = File.open(template_path).read.each_line.map(&:chomp).to_a
      env_lines = []
      normal_lines = []

      yml_content.each do |line|
        match_result = line.match(/^\{\% (set (.*?)) \%\}$/)
        if match_result
          env_lines << match_result[1]
        else
          normal_lines << line
        end
      end

      var_table = YAML.load(File.open(variable_path).read)

      normal_yml_content = normal_lines.join("\n")
      normal_yml_content

      parser = EnvParser.new(var_table)

      env_lines.each do |first_line|
        parser.update(first_line)
      end

      ruby_style_content = RubyStrParser.parse(normal_yml_content)
      parser.echo(ruby_style_content)
    end
  end
end
