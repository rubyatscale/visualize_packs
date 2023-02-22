# typed: strict

module VisualizePackwerk
  class PackageRelationships
    extend T::Sig

    OUTPUT_FILENAME = T.let('packwerk.png'.freeze, String)

    sig { params(teams: T::Array[CodeTeams::Team]).void }
    def create_package_graph_for_teams!(teams)
      packages = Packs.all.select do |package|
        teams.map(&:name).include?(CodeOwnership.for_package(package)&.name)
      end

      create_package_graph!(packages)
    end

    sig { params(teams: T::Array[CodeTeams::Team], show_all_teams: T::Boolean).void }
    def create_team_graph!(teams, show_all_teams: false)
      package_graph = PackageGraph.construct
      team_graph = TeamGraph.from_package_graph(package_graph)
      node_names = teams.map(&:name)

      draw_graph!(team_graph, node_names, show_all_nodes: show_all_teams)
    end

    sig { params(packages: T::Array[Packs::Pack]).void }
    def create_package_graph!(packages)
      graph = PackageGraph.construct
      node_names = packages.map(&:name)
      draw_graph!(graph, node_names)
    end

    sig { params(packages: T::Array[Packs::Pack], show_all_nodes: T::Boolean).void }
    def create_graph!(packages, show_all_nodes: false)
      graph = PackageGraph.construct
      node_names = packages.map(&:name)
      draw_graph!(graph, node_names, show_all_nodes: show_all_nodes)
    end

    sig { params(graph: GraphInterface, node_names: T::Array[String], show_all_nodes: T::Boolean).void }
    def draw_graph!(graph, node_names, show_all_nodes: false)
      # SFDP looks better than dot in some cases, but less good in other cases.
      # If your visualization looks bad, change the layout to other_layout!
      # https://graphviz.org/docs/layouts/
      default_layout = :dot
      # other_layout = :sfdp
      graphviz_graph = GraphViz.new(:G, type: :digraph, dpi: 100, layout: default_layout)

      # Create graph nodes
      graphviz_nodes = T.let({}, T::Hash[String, GraphViz::Node])

      nodes_to_draw = graph.nodes.select{|n| node_names.include?(n.name) }

      nodes_to_draw.each do |node|
        graphviz_nodes[node.name] = add_node(node, graphviz_graph)
      end

      max_edge_width = 10

      # Draw all edges
      nodes_to_draw.each do |node|
        node.dependencies.each do |to_node|
          next unless node_names.include?(to_node)

          graphviz_graph.add_edges(
            graphviz_nodes[node.name],
            graphviz_nodes[to_node],
            { color: 'darkgreen' }
          )
        end

        node.violations_by_node_name.each do |to_node_name, violation_count|
          next unless node_names.include?(to_node_name)

          edge_width = [
            [(violation_count / 5).to_i, 1].max, # rubocop:disable Lint/NumberConversion
            max_edge_width,
          ].min

          graphviz_graph.add_edges(
            graphviz_nodes[node.name],
            graphviz_nodes[to_node_name],
            { color: 'red', penwidth: edge_width }
          )
        end
      end

      # Save graph to filesystem
      puts "Outputting to: #{OUTPUT_FILENAME}"
      graphviz_graph.output(png: OUTPUT_FILENAME)
      puts 'Finished!'
    end

    sig { params(node: NodeInterface, graph: GraphViz).returns(GraphViz::Node) }
    def add_node(node, graph)
      node_options = {
        fontsize: 26.0,
        fontcolor: 'black',
        fillcolor: 'white',
        color: 'black',
        height: 1.0,
        style: 'filled, rounded',
        shape: 'box',
      }

      graph.add_nodes(node.name, **node_options)
    end
  end

  private_constant :PackageRelationships
end
