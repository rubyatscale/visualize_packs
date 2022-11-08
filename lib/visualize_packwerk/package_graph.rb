# typed: strict

module VisualizePackwerk
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
      @index_by_name = T.let({}, T::Hash[String, PackageNode])
    end

    sig { returns(PackageGraph) }
    def self.construct
      package_nodes = Set.new
      ParsePackwerk.all.each do |p|
        # We could consider ignoring the root!
        # We would also need to ignore it when parsing PackageNodes.
        # next if p.name == ParsePackwerk::ROOT_PACKAGE_NAME
        owner = CodeOwnership.for_package(p)
        violations_by_package = p.violations.group_by(&:to_package_name).transform_values(&:count)

        package_nodes << PackageNode.new(
          name: p.name,
          team_name: owner&.name || 'Unknown',
          violations_by_package: violations_by_package,
          dependencies: Set.new(p.dependencies)
        )
      end

      PackageGraph.new(package_nodes: package_nodes)
    end

    sig { params(name: String).returns(PackageNode) }
    def package_by_name(name)
      @index_by_name[name] ||= T.must(package_nodes.find { |node| node.name == name })
    end
  end
end
