set -x
set -e

cd spec/sample_app1
bundle

GENERATE_PNGS=$1
NEW=$2
URL="--remote-base-url=https://github.com/rubyatscale/visualize_packwerk/tree/main/spec/sample_app"

bundle exec visualize_packs $URL > test_output/plain$NEW.dot

bundle exec visualize_packs --no-legend $URL > test_output/no_legend$NEW.dot
bundle exec visualize_packs --no-layers $URL > test_output/no_layers$NEW.dot
bundle exec visualize_packs --no-dependencies $URL > test_output/no_dependencies$NEW.dot
bundle exec visualize_packs --no-todos $URL > test_output/no_todos$NEW.dot
bundle exec visualize_packs --no-privacy $URL > test_output/no_privacy$NEW.dot
bundle exec visualize_packs --no-teams $URL > test_output/no_teams$NEW.dot
bundle exec visualize_packs --no_nested_relationships $URL > test_output/no_nested_relationships$NEW.dot
bundle exec visualize_packs --roll_nested_todos_into_top_level $URL > test_output/roll_nested_todos_into_top_level$NEW.dot

bundle exec visualize_packs             --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > test_output/only_layers$NEW.dot
bundle exec visualize_packs --no-layers --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > test_output/no_to_all$NEW.dot

bundle exec visualize_packs --focus_on=packs/ui                       $URL > test_output/focussed_on_packs_ui$NEW.dot
bundle exec visualize_packs --focus_on=packs/ui --only-edges-to-focus $URL > test_output/focussed_on_packs_ui_focus_edges$NEW.dot

bundle exec visualize_packs --focus_folder=packs/model $URL > test_output/focus_folder$NEW.dot

if [ "$GENERATE_PNGS" = "GENERATE_PNGS" ]; then
  dot test_output/plain$NEW.dot -Tpng -o test_output/plain$NEW.png

  dot test_output/no_legend$NEW.dot -Tpng -o test_output/no_legend$NEW.png
  dot test_output/no_layers$NEW.dot -Tpng -o test_output/no_layers$NEW.png
  dot test_output/no_dependencies$NEW.dot -Tpng -o test_output/no_dependencies$NEW.png
  dot test_output/no_todos$NEW.dot -Tpng -o test_output/no_todos$NEW.png
  dot test_output/no_privacy$NEW.dot -Tpng -o test_output/no_privacy$NEW.png
  dot test_output/no_teams$NEW.dot -Tpng -o test_output/no_teams$NEW.png
  dot test_output/no_nested_relationships$NEW.dot -Tpng -o test_output/no_nested_relationships$NEW.png
  dot test_output/roll_nested_todos_into_top_level$NEW.dot -Tpng -o test_output/roll_nested_todos_into_top_level$NEW.png

  dot test_output/only_layers$NEW.dot -Tpng -o test_output/only_layers$NEW.png
  dot test_output/no_to_all$NEW.dot -Tpng -o test_output/no_to_all$NEW.png

  dot test_output/focussed_on_packs_ui$NEW.dot -Tpng -o test_output/focussed_on_packs_ui$NEW.png
  dot test_output/focussed_on_packs_ui_focus_edges$NEW.dot -Tpng -o test_output/focussed_on_packs_ui_focus_edges$NEW.png

  dot test_output/focus_folder$NEW.dot -Tpng -o test_output/focus_folder$NEW.png

  convert test_output/plain$NEW.png \
    test_output/no_legend$NEW.png \
    test_output/no_layers$NEW.png \
    test_output/no_dependencies$NEW.png \
    test_output/no_todos$NEW.png \
    test_output/no_privacy$NEW.png \
    test_output/no_teams$NEW.png \
    test_output/no_nested_relationships$NEW.png \
    test_output/roll_nested_todos_into_top_level$NEW.png \
    test_output/only_layers$NEW.png \
    test_output/no_to_all$NEW.png \
    test_output/focussed_on_packs_ui$NEW.png \
    test_output/focussed_on_packs_ui_focus_edges$NEW.png \
    test_output/focus_folder$NEW.png \
    -append ../../diagram_examples$NEW.png
fi
