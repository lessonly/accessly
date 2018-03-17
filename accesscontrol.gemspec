
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "accesscontrol/version"

Gem::Specification.new do |spec|
  spec.name          = "access_control_rails"
  spec.version       = Accesscontrol::VERSION
  spec.authors       = ["Aaron Milam", "Eddie Hourigan", "Ross Reinhardt"]
  spec.email         = ["devops@lessonly.com"]

  spec.summary       = %q{Simplified access control in Rails}
  spec.description   = %q{Simplified access control in Rails!}
  spec.homepage      = "https://github.com/lessonly/accesscontrol"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 5.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pry"
end
