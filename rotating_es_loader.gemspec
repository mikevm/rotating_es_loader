# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'rotating_es_loader'
  s.version = '0.0.4'
  s.date = '2019-09-25'
  s.summary = 'Rotating ES Loader'
  s.description = 'A base class for code that loads data into Elasticsearch'
  s.authors = ['Mike Kowdley']
  s.email = 'mike@valuationmetricsinc.com'

  s.files = Dir.glob("{bin,lib}/**/*") # + %w(LICENSE README.md)
  # s.files = `git ls-files -z`.split("\x0")

  s.homepage = 'https://github.com/mikevm/rotating_es_loader'
  s.license = 'MIT'

  s.add_dependency('aws-sdk', '~> 2.11.358')
  s.add_dependency('aws-sdk-resources', '~> 2.11.258')
  s.add_dependency('elasticsearch', '~> 5.0.5')
  s.add_dependency('elasticsearch-extensions', '~> 0.0.31')
  s.add_dependency('faraday_middleware', '~> 0.13.1')
  s.add_dependency('faraday_middleware-aws-signers-v4', '~> 0.1.9')
  s.add_dependency('logger', '~> 1.4.1')
  s.add_dependency('memoist', '~> 0.16.0')
  s.add_dependency('xml-simple', '~> 1.1.5')

  s.add_development_dependency('rake', '~> 12.3.3')
  s.add_development_dependency('rspec', '~> 3.8.0')
  s.add_development_dependency('rubocop', '~> 0.74.0')
  s.add_development_dependency('rubocop-rspec', '~> 1.35.0')
end
