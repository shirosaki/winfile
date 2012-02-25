# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "winfile/version"

Gem::Specification.new do |s|
  s.name        = "winfile"
  s.version     = WinFile::VERSION
  s.authors     = ["Hiroshi Shirosaki"]
  s.email       = ["h.shirosaki@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{File methods for Windows}
  s.description = %q{This provides methods which deal with Windows specific issues.}

  s.rubyforge_project = "winfile"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "minitest"
  # s.add_runtime_dependency "rest-client"
end
