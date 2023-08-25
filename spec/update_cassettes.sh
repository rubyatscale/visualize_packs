set -x
set -e

rm -f spec/sample_app1/test_output/*.dot
rm -f spec/sample_app1/test_output/*.png

./spec/diagram_generation_helper.sh GENERATE_PNGS

open diagram_examples.png