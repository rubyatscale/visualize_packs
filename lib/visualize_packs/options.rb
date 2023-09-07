# frozen_string_literal: true
# typed: strict

class EdgeTodoTypes < T::Enum
  enums do
    Dependency = new
    Privacy = new
    Architecture = new
    Visibility = new
  end
end

class FocusPackEdgeDirection < T::Enum
  enums do
    None = new
    All = new
    In = new
    Out = new
    InOut = new
  end
end

class Options < T::Struct
  extend T::Sig

  prop :show_legend, T::Boolean, default: true
  prop :show_layers, T::Boolean, default: true
  prop :show_dependencies, T::Boolean, default: true
  prop :show_todos, T::Boolean, default: true
  prop :only_todo_types, T::Array[EdgeTodoTypes], default: EdgeTodoTypes.values
  prop :show_privacy, T::Boolean, default: true
  prop :show_teams, T::Boolean, default: true

  prop :focus_pack, T::Array[String], default: []
  prop :show_only_edges_to_focus_pack, FocusPackEdgeDirection, default: FocusPackEdgeDirection::All

  prop :roll_nested_into_parent_packs, T::Boolean, default: false
  prop :show_nested_relationships, T::Boolean, default: true

  prop :exclude_packs, T::Array[String], default: []

  prop :remote_base_url, T.nilable(String)
end