set -x
set -e

cd spec/sample_app1
bundle

GENERATE_PNGS=$1
NEW=$2
URL="--remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app"

bundle exec visualize_packs $URL > tests/plain$NEW.dot

bundle exec visualize_packs --no-layers $URL > tests/no_layers$NEW.dot
bundle exec visualize_packs --no-dependencies $URL > tests/no_dependencies$NEW.dot
bundle exec visualize_packs --no-todos $URL > tests/no_todos$NEW.dot
bundle exec visualize_packs --no-privacy $URL > tests/no_privacy$NEW.dot
bundle exec visualize_packs --no-teams $URL > tests/no_teams$NEW.dot
bundle exec visualize_packs --no_nested_relationships $URL > tests/no_nested_relationships$NEW.dot
bundle exec visualize_packs --roll_nested_todos_into_top_level $URL > tests/roll_nested_todos_into_top_level$NEW.dot

bundle exec visualize_packs             --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > tests/only_layers$NEW.dot
bundle exec visualize_packs --no-layers --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > tests/no_to_all$NEW.dot

bundle exec visualize_packs --focus_on=packs/ui                       $URL > tests/focussed_on_packs_ui$NEW.dot
bundle exec visualize_packs --focus_on=packs/ui --only-edges-to-focus $URL > tests/focussed_on_packs_ui_focus_edges$NEW.dot

bundle exec visualize_packs --focus_folder=packs/model $URL > tests/focus_folder$NEW.dot

if [ "$GENERATE_PNGS" = "GENERATE_PNGS" ]; then
  dot tests/plain$NEW.dot -Tpng -o tests/plain$NEW.png

  dot tests/no_layers$NEW.dot -Tpng -o tests/no_layers$NEW.png
  dot tests/no_dependencies$NEW.dot -Tpng -o tests/no_dependencies$NEW.png
  dot tests/no_todos$NEW.dot -Tpng -o tests/no_todos$NEW.png
  dot tests/no_privacy$NEW.dot -Tpng -o tests/no_privacy$NEW.png
  dot tests/no_teams$NEW.dot -Tpng -o tests/no_teams$NEW.png
  dot tests/no_nested_relationships$NEW.dot -Tpng -o tests/no_nested_relationships$NEW.png
  dot tests/roll_nested_todos_into_top_level$NEW.dot -Tpng -o tests/roll_nested_todos_into_top_level$NEW.png

  dot tests/only_layers$NEW.dot -Tpng -o tests/only_layers$NEW.png
  dot tests/no_to_all$NEW.dot -Tpng -o tests/no_to_all$NEW.png

  dot tests/focussed_on_packs_ui$NEW.dot -Tpng -o tests/focussed_on_packs_ui$NEW.png
  dot tests/focussed_on_packs_ui_focus_edges$NEW.dot -Tpng -o tests/focussed_on_packs_ui_focus_edges$NEW.png

  dot tests/focus_folder$NEW.dot -Tpng -o tests/focus_folder$NEW.png

  convert tests/plain$NEW.png \
    tests/no_layers$NEW.png \
    tests/no_dependencies$NEW.png \
    tests/no_todos$NEW.png \
    tests/no_privacy$NEW.png \
    tests/no_teams$NEW.png \
    tests/no_nested_relationships$NEW.png \
    tests/roll_nested_todos_into_top_level$NEW.png \
    tests/only_layers$NEW.png \
    tests/no_to_all$NEW.png \
    tests/focussed_on_packs_ui$NEW.png \
    tests/focussed_on_packs_ui_focus_edges$NEW.png \
    tests/focus_folder$NEW.png \
    -append ../../diagram_examples$NEW.png
fi
