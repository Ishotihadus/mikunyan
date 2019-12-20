# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$:.unshift(lib) unless $:.include?(lib)
require 'mikunyan/version'

Gem::Specification.new do |spec|
  spec.name          = 'mikunyan'
  spec.version       = Mikunyan::VERSION
  spec.authors       = ['Ishotihadus']
  spec.email         = ['hanachan.pao@gmail.com']

  spec.summary       = 'Unity asset deserializer for Ruby'
  spec.description   = 'Library to deserialize Unity assetbundles and assets.'
  spec.homepage      = 'https://github.com/Ishotihadus/mikunyan'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}){|f| File.basename(f)}
  spec.require_paths = ['lib']
  spec.extensions    = ['ext/decoders/native/extconf.rb', 'ext/decoders/crunch/extconf.rb']

  spec.add_dependency 'bin_utils', '~> 0'
  spec.add_dependency 'chunky_png', '~> 1'
  spec.add_dependency 'extlz4', '~> 0'
  spec.add_dependency 'extlzma', '~> 0'
  spec.add_dependency 'json', '~> 2'

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'oily_png', '~> 1'
  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'rake-compiler', '~> 1'
  spec.add_development_dependency 'usamin', '~> 7'
end
