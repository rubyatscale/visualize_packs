Gem::Specification.new do |spec|
  spec.name          = "visualize_packs"
  spec.version       = '0.5.6'
  spec.authors       = ['Gusto Engineers']
  spec.email         = ['dev@gusto.com']
  spec.summary       = 'A gem to visualize connections in a Ruby app that uses packs'
  spec.description   = 'A gem to visualize connections in a Ruby app that uses packs'
  spec.homepage      = 'https://github.com/rubyatscale/visualize_packs'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/rubyatscale/visualize_packs'
    spec.metadata['changelog_uri'] = 'https://github.com/rubyatscale/visualize_packs/releases'
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

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'tapioca'

  spec.add_dependency 'packs-specification'
  spec.add_dependency 'parse_packwerk', '>= 0.20.0'
  spec.add_dependency 'sorbet-runtime'

end
