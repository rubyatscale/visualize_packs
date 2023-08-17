set -x
set -e

rm -f tests/*.dot

./spec/diagram_generation_helper.sh DONT_GENERATE_PNGS

git status

# Removing changes that we expect after a CI run
git restore spec/sample_app1/Gemfile.lock
rm -rf vendor/

if [[ `git status --porcelain` ]]; then
  echo "Changes to git detected. Fail."
  echo "Please make sure you ran './update_cassettes.sh' and checked in all changes into git."
  exit 1
else
  echo "No changes to git detected. Success."
  exit 0
fi