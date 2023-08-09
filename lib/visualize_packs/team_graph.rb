# typed: strict

module VisualizePacks
  #
  # A team graph reduces a PackageGraph by aggregating over packages owned by teams
  #
  class TeamGraph
    extend T::Sig
    include GraphInterface

    sig { override.returns(T::Set[NodeInterface]) }
    def nodes
      @team_nodes
    end

    sig { params(team_nodes: T::Set[TeamNode]).void }
    def initialize(team_nodes:)
      @team_nodes = team_nodes
    end

    sig { params(package_graph: PackageGraph).returns(TeamGraph) }
    def self.from_package_graph(package_graph)
      team_nodes = T.let(Set.new, T::Set[TeamNode])
      package_graph.package_nodes.group_by(&:team_name).each do |team, package_nodes_for_team|
        violations_by_team = {}
        package_nodes_for_team.map(&:violations_by_package).each do |new_violations_by_package|
          new_violations_by_package.each do |pack_name, count|
            # We first get the pack owner of the violated package
            other_package = package_graph.package_by_name(pack_name)
            next if other_package.nil?
            other_team = other_package.team_name
            violations_by_team[other_team] ||= 0
            # Then we add the violations on that team together
            # TODO: We may want to ignore this if team == other_team to avoid arrows pointing to self, but maybe not!
            violations_by_team[other_team] += count
          end
        end

        dependencies = Set.new
        package_nodes_for_team.map(&:dependencies).reduce(Set.new, :+).each do |dependency|
          other_pack = package_graph.package_by_name(dependency)
          next if other_pack.nil?
          dependencies << other_pack.team_name
        end

        team_nodes << TeamNode.new(
          name: team,
          violations_by_team: violations_by_team,
          dependencies: dependencies
        )
      end

      TeamGraph.new(team_nodes: team_nodes)
    end
  end
end
