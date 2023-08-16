class Options
  attr_accessor :show_layers
  attr_accessor :show_dependencies
  attr_accessor :show_todos
  attr_accessor :show_privacy
  attr_accessor :show_teams

  attr_accessor :focus_package
  attr_accessor :show_only_edges_to_focus_package

  attr_accessor :roll_nested_todos_into_top_level
  attr_accessor :focus_folder
  attr_accessor :show_nested_relationships

  attr_accessor :remote_base_url

  def initialize
    @show_layers = true
    @show_dependencies = true
    @show_todos = true
    @show_privacy = true
    @show_teams = true

    @focus_package = nil
    @show_only_edges_to_focus_package = false

    @roll_nested_todos_into_top_level = false
    @focus_folder = nil
    @show_nested_relationships = true

    @remote_base_url = nil
  end
end