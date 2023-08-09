# typed: strict

module VisualizePacks
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
      graphviz_graph = GraphViz.new(
        :G,
        type: :digraph,
        dpi: 100,
        layout: default_layout,
        label: "Visualization of #{node_names.count} packs, generated using `bin/packs`",
        fontsize: 24,
        labelloc: "t",
      )

      # Create graph nodes
      graphviz_nodes = T.let({}, T::Hash[String, GraphViz::Node])

      nodes_to_draw = graph.nodes.select{|n| node_names.include?(n.name) }

      nodes_to_draw.each do |node|
        graphviz_nodes[node.name] = add_node(node, graphviz_graph)
      end

      # Draw all edges
      nodes_to_draw.each do |node|
        node.dependencies.each do |to_node|
          next unless node_names.include?(to_node)

          add_dependency(
            graph: graphviz_graph,
            node1: T.must(graphviz_nodes[node.name]),
            node2: T.must(graphviz_nodes[to_node]),
          )
        end

        node.violations_by_node_name.each do |to_node_name, violation_count|
          next unless node_names.include?(to_node_name)

          add_violation(
            graph: graphviz_graph,
            node1: T.must(graphviz_nodes[node.name]),
            node2: T.must(graphviz_nodes[to_node_name]),
            violation_count: violation_count
          )
        end
      end

      add_legend(graphviz_graph)

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

    sig { params(graph: GraphViz).void }
    def add_legend(graph)
      legend = graph.add_graph("legend")

      # This commented out code was used to generate an image that I edited by hand.
      # I was unable to figure out how to:
      # - put a box around the legend
      # - layout the node pairs in vertical order
      # - give it a title
      # So I just generated this using graphviz and then pulled the image in.
      # a_node = legend.add_nodes("packs/a")
      # b_node = legend.add_nodes("packs/b")
      # c_node = legend.add_nodes("packs/c")
      # d_node = legend.add_nodes("packs/d")
      # e_node = legend.add_nodes("packs/e")
      # f_node = legend.add_nodes("packs/f")

      # add_dependency(graph: legend, node1: a_node, node2: b_node, label: 'Dependency in package.yml')
      # add_violation(graph: legend, node1: c_node, node2: d_node, violation_count: 1, label: 'Violations (few)')
      # add_violation(graph: legend, node1: e_node, node2: f_node, violation_count: 30, label: 'Violations (many)')

      image = legend.add_node("",
        shape: "image",
        image: Pathname.new(__dir__).join("./legend.png").to_s,
      )
    end

    sig { params(graph: GraphViz, node1: GraphViz::Node, node2: GraphViz::Node, violation_count: Integer, label: T.nilable(String)).void }
    def add_violation(graph:, node1:, node2:, violation_count:, label: nil)
      max_edge_width = 10

      edge_width = [
        [(violation_count / 5).to_i, 1].max, # rubocop:disable Lint/NumberConversion
        max_edge_width,
      ].min

      opts = { color: 'red', style: 'dashed', penwidth: edge_width }
      if label
        opts.merge!(label: label)
      end

      graph.add_edges(node1, node2, opts)
    end

    sig { params(graph: GraphViz, node1: GraphViz::Node, node2: GraphViz::Node, label: T.nilable(String)).void }
    def add_dependency(graph:, node1:, node2:, label: nil)
      opts = { color: 'darkgreen' }
      if label
        opts.merge!(label: label)
      end

      graph.add_edges(node1, node2, opts)
    end
  end

  private_constant :PackageRelationships
end
