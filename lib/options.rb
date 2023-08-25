# frozen_string_literal: true
# typed: strict

class Options < T::Struct
  extend T::Sig

  prop :show_legend, T::Boolean, default: true
  prop :show_layers, T::Boolean, default: true
  prop :show_dependencies, T::Boolean, default: true
  prop :show_todos, T::Boolean, default: true
  prop :show_privacy, T::Boolean, default: true
  prop :show_teams, T::Boolean, default: true

  prop :focus_package, T.nilable(String)
  prop :show_only_edges_to_focus_package, T::Boolean, default: false

  prop :roll_nested_todos_into_top_level, T::Boolean, default: false
  prop :focus_folder, T.nilable(String)
  prop :show_nested_relationships, T::Boolean, default: true

  prop :exclude_packs, T::Array[String], default: []
  prop :exclude_violation_types, T::Array[String], default: []
  prop :only_violation_types, T::Array[String], default: []

  prop :remote_base_url, T.nilable(String)
end