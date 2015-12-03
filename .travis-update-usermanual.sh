#!/bin/bash
# Clones testmycode usermanual repo and updates usermanual to the latest one

git clone https://github.com/testmycode-usermanual/testmycode-usermanual.github.io.git
cd testmycode-usermanual.github.io
mkdir "$TRAVIS_BUILD_ID"
cp -R ../doc/usermanual  "$TRAVIS_BUILD_ID"
git add -A
git commit -m "Add built usermanual to usermanual repo for "
git push --force "https://testmycode-usermanual:$GITHUB_API_KEY@github.com/testmycode-usermanual/testmycode-usermanual.github.io" master:master 2>&1 | sed "s/$GITHUB_API_KEY/<confidential>/g"
