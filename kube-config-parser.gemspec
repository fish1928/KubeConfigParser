Gem::Specification.new do |s|
  s.name        = 'kube-config-parser'
  s.version     = '1.0.0'
  s.date        = '2019-01-24'
  s.summary     = "KubeConfigParser"
  s.description = "a simple kube config parser"
  s.authors     = ["Yukai Jin"]
  s.email       = 'fish1928@outlook.com'
  s.homepage    = 'https://github.com/fish1928/KubeConfigParser'
  s.files       = Dir['lib/**/*.rb']
  s.files      += Dir['lib/utils/kube_config_parser/*.rb']
  s.license     = 'MIT'
end
