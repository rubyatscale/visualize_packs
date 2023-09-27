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
test_names+=("no_teams"); test_params[${test_names[-1]}]="--no-teams"

test_names+=("no_dependencies"); test_params[${test_names[-1]}]="--no-dependency-arrows --use-edge-todos-for-layout"
test_names+=("no_todos"); test_params[${test_names[-1]}]="--no-todo-edges"
test_names+=("no_privacy"); test_params[${test_names[-1]}]="--no-privacy-boxes --no-node-todos"
test_names+=("no_nested"); test_params[${test_names[-1]}]="--no-nesting-arrows"
test_names+=("no_visibility"); test_params[${test_names[-1]}]="--no-visibility-arrows"

test_names+=("relationship_todo_types"); test_params[${test_names[-1]}]="--edge-todo-types=architecture,visibility"
test_names+=("roll_nested_into_parent_packs"); test_params[${test_names[-1]}]="--roll-nested-into-parent-packs"
test_names+=("only_layers"); test_params[${test_names[-1]}]="--no-dependency-arrows --no-todo-edges --no-privacy-boxes --no-teams --no-nesting-arrows"
test_names+=("no_to_all"); test_params[${test_names[-1]}]="--title='Hide everything' --no-layers --no-visibility --no-dependency-arrows --no-todo-edges --no-privacy-boxes --no-teams --no-nesting-arrows"
test_names+=("focussed_on_packs_ui"); test_params[${test_names[-1]}]="--focus-pack=packs/ui"
test_names+=("focussed_on_packs_ui_focus_edges"); test_params[${test_names[-1]}]="--focus-pack=packs/ui --focus-pack-edge-mode=inout"
test_names+=("focussed_on_packs_ui_focus_edges_in"); test_params[${test_names[-1]}]="--focus-pack=packs/ui --focus-pack-edge-mode=in"

# Debugging...
# echo "test_names: ${test_names[@]}"
# echo "keys: ${!test_params[@]}"
# echo "values: ${test_params[@]}"

for test in "${test_names[@]}"; do
  params=${test_params[$test]}
  echo "Testing $test: $params"
  bundle exec "visualize_packs ${params} $URL" > test_output/$test$NEW.dot
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
