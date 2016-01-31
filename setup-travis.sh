#!/bin/bash
# Sets up dependencies and environment for tests to be run in Travis.
#
# This is not recommended to be run locally, and it employs some hacks and tricks to get by limitations of travis.

set -ev

# Unset bundle Gemfile, since we have multiple projects with separate Gemfiles and it will just cause confusion
unset BUNDLE_GEMFILE
# Reduce mavens memory usage
export MAVEN_OPTS="-Xms512m -Xmx1024m -XX:PermSize=1024m"

# Update bundler
gem update --system
gem --version

# Cache file containing vendor/bundle/cache - to speed up bundle install and to fix possible connection timeouts to Rubygems
wget -r -q -nH --cut-dirs=2 --no-parent -A gem  http://testmycode.net/travis/rubygems-cache/vendor/
bundle install --retry=3 --jobs=3 --deployment

# Git settings so that Travis can clone submodules
sed -i 's/git@github.com:/https:\/\/github.com\//' .gitmodules
git submodule update --init --recursive
git config --global user.email "travis@example.com"
git config --global user.name "Travis"

if [ ! -z "$RSPEC" ]
then
  # Install tmc-check
  export CHECK_INSTALL_DIR=$HOME/check
  mkdir $CHECK_INSTALL_DIR
  git clone https://github.com/testmycode/tmc-check.git
  cd tmc-check
  bundle install --jobs=3 --retry=3 --deployment
  make
  make install PREFIX=$CHECK_INSTALL_DIR
  export PATH="$CHECK_INSTALL_DIR/bin:$PATH"
  cd ..
  export LD_LIBRARY_PATH=$CHECK_INSTALL_DIR/lib:/lib:/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH
  export C_INCLUDE_PATH=$CHECK_INSTALL_DIR/include:$C_INCLUDE_PATH
  export PKG_CONFIG_PATH=$CHECK_INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
fi


# Build submodules except sandbox
bundle exec rake compile


if [ ! -z "$RSPEC" ]
then
# Use pre built tmc-sandbox
  wget -qO- http://testmycode.net/travis/sandbox-$(git submodule status ext/tmc-sandbox | grep -E -o  "[0-9a-f]{40}").tar.gz | tar xvz -C ext/
  cd ext/tmc-sandbox/web
  # Set current user and reduce max instances, though only one instance will be used at any given time
  sed -i "s/\(tmc_user: \)tmc/\1 $(whoami)/" site.defaults.yml
  sed -i "s/\(tmc_group: \)tmc/\1 $(whoami)/" site.defaults.yml
  sed -i 's/\(max_instances: \)[0-9]*/\12/' site.defaults.yml
  # Disable network
  sed -i '/^network:$/{$!{N;s/^\(network:\)\n\(  enabled: \)true$/\1\n\2false/;ty;P;D;:y}}' site.defaults.yml
  cat site.defaults.yml
  bundle install --retry=3 --jobs=3
  rake ext
  cd ../../../
fi
git clone https://github.com/testmycode/tmc-langs.git $HOME/tmc-langs
cd $HOME/tmc-langs
mvn package -Dmaven.test.skip=true
cd -
