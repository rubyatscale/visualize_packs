set -x
set -e

cd spec/sample_app1
bundle

bundle exec visualize_packs --help

# Usage: visualize_packs [options]
#         --no-layers                  Don't show architectural layers
#         --no-dependencies            Don't show accepted dependencies
#         --no-todos                   Don't show package todos
#         --no-privacy                 Don't show privacy enforcement
#         --no-teams                   Don't show team colors
#         --focus-on=PACKAGE           Don't show privacy enforcement
#         --only-edges-to-focus        If focus is set, this shows only the edges to/from the focus node instead of all edges in the focussed graph. This only has effect when --focus-on is set.
#         --remote-base-url=PACKAGE    Link package nodes to an URL (affects graphviz SVG generation)
#     -h, --help                       Show this message

URL="--remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app"

bundle exec visualize_packs $URL > tests/plain_new.dot && dot tests/plain_new.dot -Tpng -o tests/plain_new.png

bundle exec visualize_packs --no-layers $URL > tests/no_layers_new.dot && dot tests/no_layers_new.dot -Tpng -o tests/no_layers_new.png
bundle exec visualize_packs --no-dependencies $URL > tests/no_dependencies_new.dot && dot tests/no_dependencies_new.dot -Tpng -o tests/no_dependencies_new.png
bundle exec visualize_packs --no-todos $URL > tests/no_todos_new.dot && dot tests/no_todos_new.dot -Tpng -o tests/no_todos_new.png
bundle exec visualize_packs --no-privacy $URL > tests/no_privacy_new.dot && dot tests/no_privacy_new.dot -Tpng -o tests/no_privacy_new.png
bundle exec visualize_packs --no-teams $URL > tests/no_teams_new.dot && dot tests/no_teams_new.dot -Tpng -o tests/no_teams_new.png
bundle exec visualize_packs --no_nested_relationships $URL > tests/no_nested_relationships_new.dot && dot tests/no_nested_relationships_new.dot -Tpng -o tests/no_nested_relationships_new.png
bundle exec visualize_packs --roll_nested_todos_into_top_level $URL > tests/roll_nested_todos_into_top_level_new.dot && dot tests/roll_nested_todos_into_top_level_new.dot -Tpng -o tests/roll_nested_todos_into_top_level_new.png

bundle exec visualize_packs             --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > tests/only_layers_new.dot && dot tests/only_layers_new.dot -Tpng -o tests/only_layers_new.png
bundle exec visualize_packs --no-layers --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > tests/no_to_all_new.dot && dot tests/no_to_all_new.dot -Tpng -o tests/no_to_all_new.png

bundle exec visualize_packs --focus_on=packs/ui                       $URL > tests/focussed_on_packs_ui_new.dot && dot tests/focussed_on_packs_ui_new.dot -Tpng -o tests/focussed_on_packs_ui_new.png
bundle exec visualize_packs --focus_on=packs/ui --only-edges-to-focus $URL > tests/focussed_on_packs_ui_focus_edges_new.dot && dot tests/focussed_on_packs_ui_focus_edges_new.dot -Tpng -o tests/focussed_on_packs_ui_focus_edges_new.png

bundle exec visualize_packs --focus_folder=packs/model $URL > tests/focus_folder_new.dot && dot tests/focus_folder_new.dot -Tpng -o tests/focus_folder_new.png

convert tests/plain_new.png \
  tests/no_layers_new.png \
  tests/no_dependencies_new.png \
  tests/no_todos_new.png \
  tests/no_privacy_new.png \
  tests/no_teams_new.png \
  tests/no_nested_relationships_new.png \
  tests/roll_nested_todos_into_top_level_new.png \
  tests/only_layers_new.png \
  tests/no_to_all_new.png \
  tests/focussed_on_packs_ui_new.png \
  tests/focussed_on_packs_ui_focus_edges_new.png \
  tests/focus_folder_new.png \
 -append ../../diagram_examples_new.png

convert ../../diagram_examples.png ../../diagram_examples_new.png +append ../../diagram_examples_comparison.png

open ../../diagram_examples_comparison.png