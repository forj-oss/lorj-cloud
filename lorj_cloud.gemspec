# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lorj_cloud/version'

Gem::Specification.new do |spec|
  spec.name          = "lorj_cloud"
  spec.version       = LorjCloud::VERSION
  spec.authors       = ["Christophe Larsonneur"]
  spec.email         = ["clarsonneur@gmail.com"]
  spec.date          = LorjCloud::DATE

  spec.summary       = %q{Lorj cloud process.}
  spec.description   = %q{simplify cloud management, thanks to predefined process to manage cloud obj and make it work. }
  spec.homepage      = "https://github.com/forj-oss/lorj_cloud"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"

  spec.add_runtime_dependency "lorj", ">= 1.0.19"
  spec.add_runtime_dependency 'subhash', '>= 0.1.3'
  spec.add_runtime_dependency "fog", "~> 1.30.0"

  # Ruby 1.8 restrictions - BEGIN - To be removed at next major release.
  # NOTE that gemspec is used at build time. Do not use RUBY_VERSION check
  # for runtime dependency. It will influence the content of the package.
  spec.add_runtime_dependency "mime-types", '< 2.0'
  spec.add_runtime_dependency "nokogiri", '< 1.6'
  # Ruby 1.8 restrictions - END
    if RUBY_VERSION.match(/1\.8/)
    spec.add_development_dependency "ruby-debug"
  elsif RUBY_VERSION.match(/1\.9/)
    spec.add_development_dependency "debugger"
    spec.add_development_dependency "rubocop", "~> 0.30.0"
  else
    spec.add_development_dependency "byebug"
    spec.add_development_dependency "rubocop", "~> 0.30.0"
  end
end
