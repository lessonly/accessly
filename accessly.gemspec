
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "accessly/version"

Gem::Specification.new do |spec|
  spec.name          = "accessly"
  spec.version       = Accessly::VERSION
  spec.authors       = ["Aaron Milam", "Eddie Hourigan", "Ross Reinhardt"]
  spec.email         = ["devops@lessonly.com"]

  spec.summary       = %q{Simplified access control in Rails}
  spec.description   = %q{Use the policy pattern to define access control mechanisms in Rails. Store user-level, group-level, or org-level permission on any given record or concept in the database with ultra-fast lookups.}
  spec.homepage      = "https://github.com/lessonly/accessly"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 5.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "database_cleaner", "~> 1.5"
  spec.add_development_dependency "sqlite3", "~> 1.3"
  spec.add_development_dependency "rails", "~> 5.0"
end
