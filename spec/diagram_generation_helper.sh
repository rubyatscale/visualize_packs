#!/usr/bin/env bash

# set -x
set -e

cd spec/sample_app1
bundle

GENERATE_PNGS=$1
NEW=$2
URL="--remote-base-url=https://github.com/rubyatscale/visualize_packwerk/tree/main/spec/sample_app"

declare -a test_names # To keep the list of tests in the defined order
declare -A test_params # To map test names to command parameters

test_names+=("plain"); test_params[${test_names[-1]}]=""

test_names+=("no_legend"); test_params[${test_names[-1]}]="--no-legend"
test_names+=("no_layers"); test_params[${test_names[-1]}]="--no-layers"
test_names+=("no_dependencies"); test_params[${test_names[-1]}]="--no-dependencies"
test_names+=("no_todos"); test_params[${test_names[-1]}]="--no-todos"
test_names+=("only_todo_types"); test_params[${test_names[-1]}]="--only-todo-types=architecture,visibility"
test_names+=("no_privacy"); test_params[${test_names[-1]}]="--no-privacy"
test_names+=("no_teams"); test_params[${test_names[-1]}]="--no-teams"
test_names+=("no_nested_relationships"); test_params[${test_names[-1]}]="--no_nested_relationships"
test_names+=("roll_nested_into_parent_packs"); test_params[${test_names[-1]}]="--roll-nested-into-parent-packs"

test_names+=("only_layers"); test_params[${test_names[-1]}]="--no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships"
test_names+=("no_to_all"); test_params[${test_names[-1]}]="--no-layers --no-dependencies --no-todos --no-privacy --no-teams --no_nested_relationships"

test_names+=("focussed_on_packs_ui"); test_params[${test_names[-1]}]="--focus_on=packs/ui"
test_names+=("focussed_on_packs_ui_focus_edges"); test_params[${test_names[-1]}]="--focus_on=packs/ui --only-edges-to-focus"

test_names+=("focus_folder"); test_params[${test_names[-1]}]="--focus_folder=packs/model"

test_names+=("exclude_packs"); test_params[${test_names[-1]}]="--exclude-packs=packs/ui,packs/models/packs/model_a,."

# Debugging...
# echo "test_names: ${test_names[@]}"
# echo "keys: ${!test_params[@]}"
# echo "values: ${test_params[@]}"

for test in "${test_names[@]}"; do
  params=${test_params[$test]}
  echo "Testing $test: $params"
  bundle exec visualize_packs $params $URL > test_output/$test$NEW.dot
done

if [ "$GENERATE_PNGS" = "GENERATE_PNGS" ]; then
  convert_params=""
  for test in "${test_names[@]}"; do
    convert_params+=" test_output/$test$NEW.png"
    echo "Generating png for $test"
    dot test_output/$test$NEW.dot -Tpng -o test_output/$test$NEW.png
  done

  convert $convert_params -append ../../diagram_examples$NEW.png
fi
