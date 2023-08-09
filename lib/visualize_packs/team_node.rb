# typed: strict

module VisualizePacks
  class TeamNode < T::Struct
    extend T::Sig
    include NodeInterface

    const :name, String
    const :violations_by_team, T::Hash[String, Integer]
    const :dependencies, T::Set[String]

    sig { override.returns(T::Hash[String, Integer]) }
    def violations_by_node_name
      violations_by_team
    end

    sig { override.returns(String) }
    def group_name
      name
    end

    sig { override.params(node_name: String).returns(T::Boolean) }
    def depends_on?(node_name)
      dependencies.include?(node_name) || (violations_by_node_name[node_name] || 0) > 0
    end
  end
end
