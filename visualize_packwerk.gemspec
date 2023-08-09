Gem::Specification.new do |spec|
  spec.name          = "visualize_packwerk"
  spec.version       = '0.2.1'
  spec.authors       = ['Gusto Engineers']
  spec.email         = ['dev@gusto.com']
  spec.summary       = 'A gem to visualize connections in a Rails app that uses Packwerk'
  spec.description   = 'A gem to visualize connections in a Rails app that uses Packwerk'
  spec.homepage      = 'https://github.com/rubyatscale/visualize_packwerk'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/rubyatscale/visualize_packwerk'
    spec.metadata['changelog_uri'] = 'https://github.com/rubyatscale/visualize_packwerk/releases'
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  spec.executables << 'visualize_packs'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['README.md', 'lib/**/*', "bin/**/*"]
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'packs'
  spec.add_dependency 'parse_packwerk'

  spec.add_development_dependency 'bundler', '~> 2.2.16'
end
