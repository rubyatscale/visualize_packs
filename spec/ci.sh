set -x
set -e

cd sample_app1
bundle

rm -f tests/*.dot

bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app > tests/plain.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --no-layers > tests/no_layers.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --no-dependencies > tests/no_dependencies.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --no-todos > tests/no_todos.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --no-privacy > tests/no_privacy.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --no-teams > tests/no_teams.dot

bundle exec visualize_packs --no-dependencies --no-todos --no-privacy --no-teams > tests/only_layers.dot
bundle exec visualize_packs --no-layers --no-dependencies --no-todos --no-privacy --no-teams > tests/no_to_all.dot

bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_on=. > tests/focussed_on_root.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_on=packs/ui > tests/focussed_on_packs_ui.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_on=packs/models > tests/focussed_on_packs_model.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_on=packs/utility > tests/focussed_on_packs_utility.dot

bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_on=. --only-edges-to-focus > tests/focussed_on_root_focus_edges.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_on=packs/ui --only-edges-to-focus > tests/focussed_on_packs_ui_focus_edges.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_on=packs/models --only-edges-to-focus > tests/focussed_on_packs_model_focus_edges.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_on=packs/utility --only-edges-to-focus > tests/focussed_on_packs_utility_focus_edges.dot

bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --roll_nested_todos_into_top_level > tests/roll_nested_todos_into_top_level.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --focus_folder=packs/model > tests/focus_folder.dot
bundle exec visualize_packs --remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app --no_nested_relationships > tests/no_nested_relationships.dot

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