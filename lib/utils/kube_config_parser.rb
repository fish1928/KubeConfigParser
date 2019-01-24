require 'yaml'

require_relative 'kube_config_parser/paragraph'

module ParserModule
  class KubeConfigParser
    def self.parse(template_path, variable_path)
      variable_hash = YAML.load(File.open(variable_path).read)
      config_template = File.open(template_path).read

      pm = Paragraph.new(config_template, variable_hash)
      return pm.parse
    end
  end
end


if __FILE__ == $0
  template_path = "resource/hdrs/service.yml.j2.old"
  variable_path = "resource/hdrs/service_test.yml"

  puts ParserModule::KubeConfigParser.parse(template_path, variable_path)
end