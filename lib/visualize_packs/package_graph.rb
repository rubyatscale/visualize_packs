# typed: strict

module VisualizePacks
  class PackageGraph
    extend T::Sig
    include GraphInterface

    sig { returns(T::Set[PackageNode]) }
    attr_reader :package_nodes

    sig { override.returns(T::Set[NodeInterface]) }
    def nodes
      package_nodes
    end

    sig { params(package_nodes: T::Set[PackageNode]).void }
    def initialize(package_nodes:)
      @package_nodes = package_nodes
      @index_by_name = T.let({}, T::Hash[String, T.nilable(PackageNode)])
    end

    sig { returns(PackageGraph) }
    def self.construct
      package_nodes = Set.new
      Packs.all.each do |p|
        owner = CodeOwnership.for_package(p)

        # Here we need to load the package violations and dependencies,
        # so we need to use ParsePackwerk to parse that information.
        package_info = ParsePackwerk.find(p.name)
        next unless package_info # This should not happen unless packs/parse_packwerk change implementation

        violations = package_info.violations
        violations_by_package = violations.group_by(&:to_package_name).transform_values(&:count)

        dependencies = package_info.dependencies

        package_nodes << PackageNode.new(
          name: p.name,
          team_name: owner&.name || 'Unknown',
          violations_by_package: violations_by_package,
          dependencies: Set.new(dependencies)
        )
      end

      PackageGraph.new(package_nodes: package_nodes)
    end

    sig { params(name: String).returns(T.nilable(PackageNode)) }
    def package_by_name(name)
      @index_by_name[name] ||= package_nodes.find { |node| node.name == name }
    end
  end
end
