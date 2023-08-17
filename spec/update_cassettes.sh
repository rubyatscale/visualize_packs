set -x
set -e

rm -f tests/*.dot
rm -f tests/*.png

URL="--remote-base-url=https://github.com/shageman/visualize_packwerk/tree/main/spec/sample_app"

./spec/diagram_generation_helper.sh GENERATE_PNGS

open diagram_examples.png