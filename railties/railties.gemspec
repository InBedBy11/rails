$:.unshift "lib"
require "rails/version"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'railties'
  s.version     = Rails::VERSION::STRING
  s.summary     = 'Tools for creating, working with, and running Rails applications.'
  s.description = 'Rails internals: application bootup, plugins, generators, and rake tasks.'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'David Heinemeier Hansson'
  s.email             = 'david@loudthinking.com'
  s.homepage          = 'http://www.rubyonrails.org'
  s.rubyforge_project = 'rails'

  s.files              = Dir['CHANGELOG', 'README', 'bin/**/*', 'builtin/**/*', 'guides/**/*', 'lib/**/{*,.[a-z]*}']
  s.require_path       = 'lib'
  s.bindir             = 'bin'
  s.executables        = ['rails']
  s.default_executable = 'rails'

  s.rdoc_options << '--exclude' << '.'
  s.has_rdoc = false

  s.add_dependency('rake',          '>= 0.8.3')
  s.add_dependency('thor',          '~> 0.13.4')
  s.add_dependency('activesupport', "= #{Rails::VERSION::STRING}")
  s.add_dependency('actionpack',    "= #{Rails::VERSION::STRING}")
end
