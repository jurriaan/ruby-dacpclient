lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dacpclient/version'

Gem::Specification.new do |spec|
  spec.name          = 'dacpclient'
  spec.version       = DACPClient::VERSION
  spec.authors       = ['Jurriaan Pruis']
  spec.email         = ['email@jurriaanpruis.nl']
  spec.description   = 'A DACP (iTunes Remote protocol) client written in the wonderful Ruby language'
  spec.summary       = 'A DACP (iTunes Remote protocol) client written in the wonderful Ruby language'
  spec.homepage      = 'https://github.com/jurriaan/ruby-dacpclient'
  spec.license       = 'MIT'
  spec.platform      = Gem::Platform::RUBY

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']
  spec.extra_rdoc_files = ['README.md', 'LICENSE']

  spec.add_runtime_dependency 'dnssd', '~> 2.0'

  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'redcarpet'
  spec.add_development_dependency 'github-markup'
  spec.required_ruby_version = '>= 2.0.0'
end
