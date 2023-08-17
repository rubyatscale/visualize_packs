set -x
set -e

cd sample_app1
bundle

rm -f tests/*.dot

URL="--remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app"

bundle exec visualize_packs $URL > tests/plain.dot
bundle exec visualize_packs --no-layers $URL > tests/no_layers.dot
bundle exec visualize_packs --no-dependencies $URL > tests/no_dependencies.dot
bundle exec visualize_packs --no-todos $URL > tests/no_todos.dot
bundle exec visualize_packs --no-privacy $URL > tests/no_privacy.dot
bundle exec visualize_packs --no-teams $URL > tests/no_teams.dot
bundle exec visualize_packs --roll_nested_todos_into_top_level $URL > tests/roll_nested_todos_into_top_level.dot
bundle exec visualize_packs --no_nested_relationships $URL > tests/no_nested_relationships.dot

bundle exec visualize_packs             --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > tests/only_layers.dot
bundle exec visualize_packs --no-layers --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships $URL > tests/no_to_all.dot

bundle exec visualize_packs --focus_on=packs/ui $URL > tests/focussed_on_packs_ui.dot
bundle exec visualize_packs --focus_on=packs/ui --only-edges-to-focus $URL > tests/focussed_on_packs_ui_focus_edges.dot

bundle exec visualize_packs --focus_folder=packs/model $URL > tests/focus_folder.dot

git status

# Removing changes that we expect after a CI run
git restore Gemfile.lock
rm -rf ../../vendor/

if [[ `git status --porcelain` ]]; then
  echo "Changes to git detected. Fail."
  exit 1
else
  echo "No changes to git detected. Success."
  exit 0
fi