# frozen_string_literal: true
#typed: strict

require "pathname"
require "optparse"
require "ostruct"

class OptionsParser
  extend T::Sig

  sig { params(args: T::Array[String]).returns(Options) }
  def self.parse(args)
    options = Options.new

    OptionParser.new do |opt|
      opt.on('--no-legend', "Don't show legend") { |o| options.show_legend = false }

      opt.on('--no-dependency-arrows', "Don't show accepted dependency arrows") { |o| options.show_dependencies = false }
      opt.on('--no-privacy-boxes', "Don't show privacy enforcement box on a pack") { |o| options.show_privacy = false }
      opt.on('--no-layers', "Don't show architectural layers") { |o| options.show_layers = false }
      opt.on('--no-visibility-arrows', "Don't show visibility arrows") { |o| options.show_visibility = false }

      opt.on('--no-todo-edges', "Don't show todos for package relationships") { |o| options.show_relationship_todos = false }
      opt.on("--edge-todo-types=STRING", "Show only the selected types of relationship todos. Comma-separated list of #{EdgeTodoTypes.values.map &:serialize}") { |o| options.relationship_todo_types = o.to_s.split(",").uniq.map { EdgeTodoTypes.deserialize(_1) } }
      opt.on("--use-edge-todos-for-layout", "Show only the selected types of relationship todos. Comma-separated list of #{EdgeTodoTypes.values.map &:serialize}") { |o| options.use_relationship_todos_for_layout = true }

      opt.on('--no-teams', "Don't show team colors") { |o| options.show_teams = false }
      opt.on('--no-node-todos', "Don't show package-based todos") { |o| options.show_node_todos = false }

      opt.on('--focus-pack=STRING', "Focus on a specific pack(s). Comma-separated list of packs. Wildcards supported: 'packs/*'") { |o| options.focus_pack = o.to_s.split(",") }
      opt.on('--focus-pack-edge-mode=STRING', "If focus-pack is set, this shows only between focussed packs (when set to none) or the edges into / out of / in and out of the focus packs to non-focus packs (which will be re-added to the graph). One of #{FocusPackEdgeDirection.values.map &:serialize}") { |o| options.show_only_edges_to_focus_pack = FocusPackEdgeDirection.deserialize(o) }
      opt.on('--exclude-packs=', "Exclude listed packs from diagram. If used with include you will get all included that are not excluded. Wildcards support: 'packs/ignores/*'") { |o| options.exclude_packs = o.to_s.split(",") }

      opt.on('--roll-nested-into-parent-packs', "Don't show nested packs (not counting root). Connect edges to top-level pack instead") { |o| options.roll_nested_into_parent_packs = true }
      opt.on('--no-nesting-arrows', "Don't draw relationships between parents and nested packs") { |o| options.show_nested_relationships = false }

      opt.on('--remote-base-url=STRING', "Link pack packs to a URL (affects graphviz SVG generation)") { |o| options.remote_base_url = o }

      opt.on('--title=STRING', "Set a custom diagram title") { |o| options.title = o }

      opt.on('-V', '--version', "Show version") do
        spec_path = File.expand_path("../visualize_packs.gemspec", __dir__)
        spec = Gem::Specification::load(spec_path)
        puts "Version #{spec.version}"
        exit
      end

      opt.on_tail("-h", "--help", "Show this message") do
        puts opt
        exit
      end
    end.parse(args)

    options
  end
end

