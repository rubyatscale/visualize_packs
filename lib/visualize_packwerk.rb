# typed: strict

module VisualizePackwerk
  require 'visualize_packwerk/railtie' if defined?(Rails)
  require 'parse_packwerk'
  require 'code_ownership'
  require 'graphviz'

  require 'visualize_packwerk/node_interface'
  require 'visualize_packwerk/graph_interface'
  require 'visualize_packwerk/team_node'
  require 'visualize_packwerk/package_node'
  require 'visualize_packwerk/team_graph'
  require 'visualize_packwerk/package_graph'
  require 'visualize_packwerk/package_relationships'
end
