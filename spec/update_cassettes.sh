set -x
set -e

cd spec/sample_app1
bundle

rm -f tests/*.dot
rm -f tests/*.png

URL="--remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app"

bundle exec visualize_packs $URL > tests/plain.dot && dot tests/plain.dot -Tpng -o tests/plain.png

bundle exec visualize_packs --no-layers $URL > tests/no_layers.dot && dot tests/no_layers.dot -Tpng -o tests/no_layers.png
bundle exec visualize_packs --no-dependencies $URL > tests/no_dependencies.dot && dot tests/no_dependencies.dot -Tpng -o tests/no_dependencies.png
bundle exec visualize_packs --no-todos $URL > tests/no_todos.dot && dot tests/no_todos.dot -Tpng -o tests/no_todos.png
bundle exec visualize_packs --no-privacy $URL > tests/no_privacy.dot && dot tests/no_privacy.dot -Tpng -o tests/no_privacy.png
bundle exec visualize_packs --no-teams $URL > tests/no_teams.dot && dot tests/no_teams.dot -Tpng -o tests/no_teams.png
bundle exec visualize_packs --no_nested_relationships $URL > tests/no_nested_relationships.dot && dot tests/no_nested_relationships.dot -Tpng -o tests/no_nested_relationships.png
bundle exec visualize_packs --roll_nested_todos_into_top_level $URL > tests/roll_nested_todos_into_top_level.dot && dot tests/roll_nested_todos_into_top_level.dot -Tpng -o tests/roll_nested_todos_into_top_level.png

bundle exec visualize_packs             --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > tests/only_layers.dot && dot tests/only_layers.dot -Tpng -o tests/only_layers.png
bundle exec visualize_packs --no-layers --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > tests/no_to_all.dot && dot tests/no_to_all.dot -Tpng -o tests/no_to_all.png

bundle exec visualize_packs --focus_on=packs/ui                       $URL > tests/focussed_on_packs_ui.dot && dot tests/focussed_on_packs_ui.dot -Tpng -o tests/focussed_on_packs_ui.png
bundle exec visualize_packs --focus_on=packs/ui --only-edges-to-focus $URL > tests/focussed_on_packs_ui_focus_edges.dot && dot tests/focussed_on_packs_ui_focus_edges.dot -Tpng -o tests/focussed_on_packs_ui_focus_edges.png

bundle exec visualize_packs --focus_folder=packs/model $URL > tests/focus_folder.dot && dot tests/focus_folder.dot -Tpng -o tests/focus_folder.png

convert \
  tests/plain.png \
  tests/no_layers.png \
  tests/no_dependencies.png \
  tests/no_todos.png \
  tests/no_privacy.png \
  tests/no_teams.png \
  tests/no_nested_relationships.png \
  tests/roll_nested_todos_into_top_level.png \
  tests/only_layers.png \
  tests/no_to_all.png \
  tests/focussed_on_packs_ui.png \
  tests/focussed_on_packs_ui_focus_edges.png \
  tests/focus_folder.png \
  -append ../../diagram_examples.png

open ../../diagram_examples.png