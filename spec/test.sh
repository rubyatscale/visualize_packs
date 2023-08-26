set -x
set -e

bundle exec rspec

./spec/diagram_generation_helper.sh GENERATE_PNGS _new

convert diagram_examples.png diagram_examples_new.png +append diagram_examples_comparison.png

open diagram_examples_comparison.png