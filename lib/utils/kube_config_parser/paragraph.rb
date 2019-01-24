require 'extensions/to_os'

require_relative 'parameter_center'
require_relative 'expression'
require_relative 'explainer'

class Paragraph
  def initialize(paragraph_content, variable_content)
    @paragraph_lines = paragraph_content.lines.map(&:chomp)
    @variables = {:item => OpenStruct.to_os(variable_content)}

    ParameterCenter.instance.register_item(@variables)
    ParameterCenter.instance.register_item(Expression.expression_map)
  end

  def parse
    explainer = Explainer.new(self)
    lines = Marshal.load(Marshal.dump(@paragraph_lines))
    new_lines = explainer.explain(lines)
    return new_lines
  end
end


if __FILE__ == $0
  yaml_file = 'resource/service_master.yml'
  require 'yaml'
  variable_hash = YAML.load(File.open(yaml_file).read)

  config_template_file= 'resource/service.yml.j2'
  config_template = File.open(config_template_file).read

  pm = Paragraph.new(config_template, variable_hash)
  pm.parse
end