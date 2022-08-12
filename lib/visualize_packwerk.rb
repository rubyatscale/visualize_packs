# typed: strict

module VisualizePackwerk
  require 'visualize_packwerk/railtie' if defined?(Rails)
  require 'parse_packwerk'
  require 'code_ownership'
  require 'package_protections'
  require 'graphviz'
end
