Gem::Specification.new do |s|
  s.name = "dotkey"
  s.version = "1.0.0"
  s.summary = "Interact with nested Ruby data structures using dot-delimited strings"
  s.description = "DotKey provides an elegant way to read, write, and manipulate deeply nested Hashes and Arrays using dot-delimited strings. It supports wildcards for pattern matching, custom delimiters, and flexible handling of missing values - making it ideal for working with complex data structures, configuration objects, and API responses."
  s.authors = ["Simon J"]
  s.email = "2857218+mwnciau@users.noreply.github.com"
  s.files = [
    "lib/dotkey.rb",
    "lib/dotkey/dot_key.rb",
    "CHANGELOG.md",
    "LICENSE.md",
    "README.md",
  ]
  s.require_paths = ["lib"]
  s.homepage = "https://rubygems.org/gems/dotkey"
  s.metadata = {
    "source_code_uri" => "https://github.com/mwnciau/dotkey",
    "changelog_uri" => "https://github.com/mwnciau/dotkey/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/mwnciau/dotkey",
    "bug_tracker_uri" => "https://github.com/mwnciau/dotkey/issues",
  }

  s.license = "MIT"
  s.required_ruby_version = ">= 2.0.0"

  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "minitest-reporters", "~> 1.1"
  s.add_development_dependency "standard", "~> 1.49"
  s.add_development_dependency "rubocop", "~> 1.75"
  s.add_development_dependency "benchmark-ips", "~> 2.14"
end
