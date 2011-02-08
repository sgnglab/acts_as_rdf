#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'acts_as_rdf'
  gem.homepage           = 'http://anise.slis.tsukuba.ac.jp/'
  gem.summary            = 'RailsでRDFをモデルとして使うためのライブラリ .'

  gem.authors            = ['Noki Kawamukai']
  gem.email              = 'naoki.kawamukai@gmail.com'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(README MIT-LICENSE) + Dir.glob('lib/**/*.rb')
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.8.1'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf', '>= 0.3.0'
  gem.add_runtime_dependency     'addressable', '>= 2.2'
  gem.add_development_dependency 'yard',        '>= 0.6.0'
  gem.add_development_dependency 'rspec',       '>= 2.4.0'
  gem.post_install_message       = nil
end
