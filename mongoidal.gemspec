# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoidal/version'

Gem::Specification.new do |spec|
  spec.name          = "mongoidal"
  spec.version       = Mongoidal::VERSION
  spec.authors       = ["jake hoffner"]
  spec.email         = ["jake.hoffner@gmail.com"]
  spec.summary       = %q{Mongoid extensions and utilities}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mongoid-slug"
  spec.add_development_dependency "mongoid", '~> 5.4.0'
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "sidekiq"
  spec.add_development_dependency "globalid"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "mongoid-rspec"
end
