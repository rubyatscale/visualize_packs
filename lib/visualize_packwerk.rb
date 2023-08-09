# typed: strict

require 'packs-specification'
require 'parse_packwerk'
require 'code_ownership'
require 'graphviz'
require 'sorbet-runtime'

require 'visualize_packs/node_interface'
require 'visualize_packs/graph_interface'
require 'visualize_packs/team_node'
require 'visualize_packs/package_node'
require 'visualize_packs/team_graph'
require 'visualize_packs/package_graph'
require 'visualize_packs/package_relationships'

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
