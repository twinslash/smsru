# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smsru/version'

Gem::Specification.new do |gem|
  gem.name          = "smsru"
  gem.version       = Smsru::VERSION
  gem.authors       = ["MrGood"]
  gem.email         = ["kuntsevichh@gmail.com"]
  gem.description   = %q{Simple wrapper for sms.ru API}
  gem.summary       = %q{very simple}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('httparty')
end
