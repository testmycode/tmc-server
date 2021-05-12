#!/bin/bash
# Clones testmycode usermanual repo and updates usermanual to the latest one

if [ ! -z $GITHUB_TOKEN ]
then
  git clone https://github.com/testmycode-usermanual/testmycode-usermanual.github.io.git
  cd testmycode-usermanual.github.io
  ls -lar ../doc/
  cp -R ../doc/usermanual .
  ls -lar
  git diff
  git add -A
  git commit -m "Add built usermanual to usermanual repo for "
  git push --force "https://testmycode-usermanual:$GITHUB_TOKEN@github.com/testmycode-usermanual/testmycode-usermanual.github.io" master:master 2>&1 | sed "s/$GITHUB_TOKEN/<confidential>/g"
fi
