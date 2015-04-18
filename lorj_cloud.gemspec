# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lorj_cloud/version'

Gem::Specification.new do |spec|
  spec.name          = "lorj_cloud"
  spec.version       = LorjCloud::VERSION
  spec.authors       = ["Christophe Larsonneur"]
  spec.email         = ["clarsonneur@gmail.com"]

  spec.summary       = %q{Lorj cloud process.}
  spec.description   = %q{simplify cloud management, thanks to predefined process to manage cloud obj and make it work. }
  spec.homepage      = "https://github.com/forj-oss/lorj_cloud"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

#  if spec.respond_to?(:metadata)
#    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
#  end

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  
  spec.add_runtime_dependency "lorj", "~> 1.0.11"
  spec.add_runtime_dependency "fog", "~> 1.30.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"
end
