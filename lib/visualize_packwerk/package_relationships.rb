# typed: strict

module VisualizePackwerk
  class PackageRelationships
    extend T::Sig

    OUTPUT_FILENAME = T.let('packwerk.png'.freeze, String)

    sig { void }
    def initialize
      @colors_by_team = T.let({}, T::Hash[String, String])
      @remaining_colors = T.let(
        [
          # Found using https://htmlcolorcodes.com/color-picker/
          '#77EE77', # green
          '#DFEE77', # yellow
          '#77EEE6', # teal
          '#EEC077', # orange
          '#EE77BF', # pink
          '#EE6F6F', # red
          '#ED6EDE', # magenta
          '#8E8CFE', # blue
          '#EEA877', # red-orange
        ], T::Array[String]
      )
    end

    sig { params(teams: T::Array[CodeTeams::Team]).void }
    def create_package_graph_for_teams!(teams)
      packages = ParsePackwerk.all.select do |package|
        teams.map(&:name).include?(CodeOwnership.for_package(package)&.name)
      end

      create_package_graph!(packages)
    end

    sig { params(teams: T::Array[CodeTeams::Team], show_all_teams: T::Boolean).void }
    def create_team_graph!(teams, show_all_teams: false)
      package_graph = PackageGraph.construct
      team_graph = TeamGraph.from_package_graph(package_graph)
      highlighted_node_names = teams.map(&:name)

      draw_graph!(team_graph, highlighted_node_names, show_all_nodes: show_all_teams)
    end

    sig { params(packages: T::Array[ParsePackwerk::Package], show_all_packs: T::Boolean).void }
    def create_package_graph!(packages, show_all_packs: false)
      graph = PackageGraph.construct
      highlighted_node_names = packages.map(&:name)
      draw_graph!(graph, highlighted_node_names, show_all_nodes: show_all_packs)
    end

    sig { params(packages: T::Array[ParsePackwerk::Package], show_all_nodes: T::Boolean).void }
    def create_graph!(packages, show_all_nodes: false)
      graph = PackageGraph.construct
      highlighted_node_names = packages.map(&:name)
      draw_graph!(graph, highlighted_node_names, show_all_nodes: show_all_nodes)
    end

    sig { params(graph: GraphInterface, highlighted_node_names: T::Array[String], show_all_nodes: T::Boolean).void }
    def draw_graph!(graph, highlighted_node_names, show_all_nodes: false)
      # SFDP looks better than dot in some cases, but less good in other cases.
      # If your visualization looks bad, change the layout to other_layout!
      # https://graphviz.org/docs/layouts/
      default_layout = :dot
      # other_layout = :sfdp
      graphviz_graph = GraphViz.new(:G, type: :digraph, dpi: 100, layout: default_layout)

      # Create graph nodes
      graphviz_nodes = T.let({}, T::Hash[String, GraphViz::Node])

      nodes_to_draw = graph.nodes

      nodes_to_draw.each do |node|
        next unless highlighted_node_names.any? { |highlighted_node_name| node.depends_on?(highlighted_node_name) } || highlighted_node_names.include?(node.name)

        highlight_node = highlighted_node_names.include?(node.name) && !show_all_nodes
        graphviz_nodes[node.name] = add_node(node, graphviz_graph, highlight_node)
      end

      max_edge_width = 10

      # Draw all edges
      nodes_to_draw.each do |node|
        node.dependencies.each do |to_node|
          next unless highlighted_node_names.include?(to_node)

          graphviz_graph.add_edges(
            graphviz_nodes[node.name],
            graphviz_nodes[to_node],
            { color: 'darkgreen' }
          )
        end

        node.violations_by_node_name.each do |to_node_name, violation_count|
          next unless highlighted_node_names.include?(to_node_name)

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

    sig { params(node: NodeInterface, graph: GraphViz, highlight_node: T::Boolean).returns(GraphViz::Node) }
    def add_node(node, graph, highlight_node)
      default_node_options = {
        fontsize: 26.0,
        fontcolor: 'white',
        fillcolor: 'black',
        color: 'black',
        height: 1.0,
        style: 'filled, rounded',
        shape: 'box',
      }

      node_options = if highlight_node
        default_node_options.merge(
          fillcolor: highlight_by_group(node),
          color: highlight_by_group(node),
          fontcolor: 'black'
        )
      else
        default_node_options
      end

      graph.add_nodes(node.name, **node_options)
    end

    sig { params(node: NodeInterface).returns(String) }
    def highlight_by_group(node)
      highlighted_package_color = @colors_by_team[node.group_name]
      if !highlighted_package_color
        highlighted_package_color = @remaining_colors.first
        raise 'Can only color nodes a max of 5 unique colors for now' if highlighted_package_color.nil?

        @remaining_colors.delete(highlighted_package_color)
        @colors_by_team[node.group_name] = highlighted_package_color
      end

      highlighted_package_color
    end
  end

  private_constant :PackageRelationships
end
