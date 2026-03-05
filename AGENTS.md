This file provides guidance to AI coding agents when working with code in this repository.

## What this project is

`visualize_packs` is a Ruby gem that generates visual diagrams of pack connections in a Rails application using [packs](https://github.com/rubyatscale/packs) and packwerk. It helps teams understand dependency relationships and identify architectural issues.

## Commands

```bash
bundle install

# Run all tests (RSpec)
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/path/to/spec.rb

# Type checking (Sorbet)
bundle exec srb tc
```

## Architecture

- `lib/visualize_packs.rb` — entry point; reads pack configuration and produces graph output
- `lib/visualize_packs/` — core logic: graph building, layout, and rendering (e.g. to DOT/SVG)
- `spec/` — RSpec tests; `spec/sample_app1/` contains a sample pack-structured application used in tests
