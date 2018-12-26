require 'pathname'
require 'yaml'

require 'utils/kube_config_parser'

template_file = Pathname.new('test/resource/service.yml.j2')
variable_file = Pathname.new('test/resource/service_test.yml')

result = ParserModule::KubeConfigParser.parse(template_file, variable_file)
yaml_config = YAML.load(result)
puts "yaml load success."

