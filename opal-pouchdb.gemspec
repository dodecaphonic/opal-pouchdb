# -*- encoding: utf-8 -*-
require File.expand_path("../lib/opal/pouchdb/version", __FILE__)

Gem::Specification.new do |s|
  s.name         = "opal-pouchdb"
  s.version      = Opal::PouchDB::VERSION
  s.author       = "Vitor Capela"
  s.email        = "dodecaphonic@gmail.com"
  s.homepage     = "https://github.com/dodecaphonic/opal-pouchdb"
  s.summary      = "Opal bridge to PouchDB"
  s.description  = "An Opal bridge to the PouchDB database library"

  s.files          = `git ls-files`.split("\n")
  s.executables    = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths  = ["lib"]

  s.add_runtime_dependency "opal", ">= 0.7.0", "< 0.9.0"
  s.add_development_dependency "opal-rspec", "~> 0.4.0"
  s.add_development_dependency "yard"
  s.add_development_dependency "rake"
end
