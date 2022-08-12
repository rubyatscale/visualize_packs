# typed: strict

module VisualizePackwerk
  class PackageNode < T::Struct
    extend T::Sig
    include NodeInterface

    const :name, String
    const :team_name, String
    const :violations_by_package, T::Hash[String, Integer]
    const :dependencies, T::Set[String]

    sig { override.returns(T::Hash[String, Integer]) }
    def violations_by_node_name
      violations_by_package
    end

    sig { override.returns(String) }
    def group_name
      team_name
    end

    sig { override.params(node_name: String).returns(T::Boolean) }
    def depends_on?(node_name)
      dependencies.include?(node_name) || (violations_by_package[node_name] || 0) > 0
    end
  end
end
