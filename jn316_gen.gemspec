$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "jn316_gen/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "jn316_gen"
  s.version     = Jn316Gen::VERSION
  s.authors     = ["Vladimir Támara Patiño"]
  s.email       = ["vtamara@pasosdeJesus.org"]
  s.homepage    = "https://gitlab.com/pasosdeJesus/jn316_gen"
  s.summary     = "Motor para autenticar con directorio LDAP y administración básica de usuarios y grupos"
  s.description = ""
  s.license     = "Dominio Público de acuerdo a Legislación Colombiana"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENCIA", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  s.add_dependency "msip"
  s.add_dependency "net-ldap"
end
