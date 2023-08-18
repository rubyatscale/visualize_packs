set -x
set -e

rm -f tests/*.dot
rm -f tests/*.png

./spec/diagram_generation_helper.sh GENERATE_PNGS

open diagram_examples.png