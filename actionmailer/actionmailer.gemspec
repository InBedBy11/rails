$:.unshift "lib"
require "action_mailer/version"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'actionmailer'
  s.version     = ActionMailer::VERSION::STRING
  s.summary     = 'Email composition, delivery, and receiving framework (part of Rails).'
  s.description = 'Email on Rails. Compose, deliver, receive, and test emails using the familiar controller/view pattern. First-class support for multipart email and attachments.'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'David Heinemeier Hansson'
  s.email             = 'david@loudthinking.com'
  s.homepage          = 'http://www.rubyonrails.org'
  s.rubyforge_project = 'actionmailer'

  s.files        = Dir['CHANGELOG', 'README', 'MIT-LICENSE', 'lib/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = true

  s.add_dependency('actionpack',  "= #{ActionMailer::VERSION::STRING}")
  s.add_dependency('mail',        '~> 2.1.3')
  s.add_dependency('text-format', '~> 1.0.0')
end
