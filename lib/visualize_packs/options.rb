# frozen_string_literal: true
# typed: strict

class EdgeTodoTypes < T::Enum
  enums do
    Dependency = new
    Privacy = new
    Architecture = new
    Visibility = new
    Nested_Visibility = new
  end
end

class FocusPackEdgeDirection < T::Enum
  enums do
    None = new # don't include non-focus packs and thus show no edges to/from them
    All = new # include non-focus packs and show all edges between all visible nodes
    In = new # include non-focus packs and show edges that go towards focus packs (and show all edges between focus packs)
    Out = new # include non-focus packs and show edges that go away from focus packs (and show all edges between focus packs)
    InOut = new # include non-focus packs and show edges that go towards or away from focus packs (and show all edges between focus packs)
  end
end

class Options < T::Struct
  extend T::Sig

  prop :show_legend, T::Boolean, default: true

  prop :show_dependencies, T::Boolean, default: true
  prop :show_privacy, T::Boolean, default: true
  prop :show_layers, T::Boolean, default: true
  prop :show_visibility, T::Boolean, default: true

  prop :show_relationship_todos, T::Boolean, default: true
  prop :relationship_todo_types, T::Array[EdgeTodoTypes], default: EdgeTodoTypes.values
  prop :use_relationship_todos_for_layout, T::Boolean, default: false

  prop :show_teams, T::Boolean, default: true
  prop :show_node_todos, T::Boolean, default: true

  prop :focus_pack, T.nilable(T::Array[String]), default: nil
  prop :show_only_edges_to_focus_pack, FocusPackEdgeDirection, default: FocusPackEdgeDirection::All
  prop :exclude_packs, T::Array[String], default: []

  prop :roll_nested_into_parent_packs, T::Boolean, default: false
  prop :show_nested_relationships, T::Boolean, default: true

  prop :remote_base_url, T.nilable(String)

  prop :title, T.nilable(String), default: nil
end