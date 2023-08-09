# typed: strict

require 'packs'
require 'parse_packwerk'
require 'code_ownership'
require 'graphviz'
require 'sorbet-runtime'

require 'visualize_packwerk/node_interface'
require 'visualize_packwerk/graph_interface'
require 'visualize_packwerk/team_node'
require 'visualize_packwerk/package_node'
require 'visualize_packwerk/team_graph'
require 'visualize_packwerk/package_graph'
require 'visualize_packwerk/package_relationships'

module VisualizePackwerk
  extend T::Sig

  sig { params(packages: T::Array[Packs::Pack]).void }
  def self.package_graph!(packages)
    PackageRelationships.new.create_package_graph!(packages)
  end

  sig { params(teams: T::Array[CodeTeams::Team]).void }
  def self.team_graph!(teams)
    PackageRelationships.new.create_team_graph!(teams)
  end
end
