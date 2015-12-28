#!/bin/bash -e
# Sets up dependencies and environment for tests to be run in Travis.
#
# This is not recommended to be run locally, and it employs some hacks and tricks to get by limitations of travis.

# Use the announce pattern instead of set -x or -v since the setting will be inherited back to the .travis.yml
# and if will just print everything and it breaks the folds.
# We want the exports to be inherited back to .travis.yml b/c the exports done here...
announce() {
  echo \$ $@
  $@
}

# Unset bundle Gemfile, since we have multiple projects with separate Gemfiles and it will just cause confusion
unset BUNDLE_GEMFILE

# Update bundler
announce gem update --system
announce gem --version

# Cache file containing vendor/bundle/cache - to speed up bundle install and to fix possible connection timeouts to Rubygems
announce wget -r -q -nH --cut-dirs=2 --no-parent -A gem  http://testmycode.net/travis/rubygems-cache/vendor/
announce bundle install --retry=3 --jobs=3 --deployment

# Git settings so that Travis can clone submodules
announce sed -i 's/git@github.com:/https:\/\/github.com\//' .gitmodules
announce git submodule update --init --recursive
announce git config --global user.email "travis@example.com"
announce git config --global user.name "Travis"

# Install tmc-check
announce export CHECK_INSTALL_DIR=$HOME/check
announce mkdir $CHECK_INSTALL_DIR
announce git clone https://github.com/testmycode/tmc-check.git
announce cd tmc-check
announce bundle install --jobs=3 --retry=3 --deployment
announce make
announce make install PREFIX=$CHECK_INSTALL_DIR
announce export PATH="$CHECK_INSTALL_DIR/bin:$PATH"
announce cd ..
announce export LD_LIBRARY_PATH=$CHECK_INSTALL_DIR/lib:/lib:/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH
announce export C_INCLUDE_PATH=$CHECK_INSTALL_DIR/include:$C_INCLUDE_PATH
announce export PKG_CONFIG_PATH=$CHECK_INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH

# Reduce mavens memory usage
announce export MAVEN_OPTS="-Xms512m -Xmx1024m -XX:PermSize=1024m"

# Build submodules except sandbox
announce bundle exec rake compile

# Use pre built tmc-sandbox
announce wget -qO- http://testmycode.net/travis/sandbox-$(git submodule status ext/tmc-sandbox | grep -E -o  "[0-9a-f]{40}").tar.gz | tar xvz -C ext/
announce cd ext/tmc-sandbox/web
# Set current user and reduce max instances, though only one instance will be used at any given time
sed -i "s/\(tmc_user: \)tmc/\1 $(whoami)/" site.defaults.yml
sed -i "s/\(tmc_group: \)tmc/\1 $(whoami)/" site.defaults.yml
sed -i 's/\(max_instances: \)[0-9]*/\12/' site.defaults.yml
# Disable network
sed -i '/^network:$/{$!{N;s/^\(network:\)\n\(  enabled: \)true$/\1\n\2false/;ty;P;D;:y}}' site.defaults.yml
announce cat site.defaults.yml
announce bundle install --retry=3 --jobs=3
announce rake ext
announce cd ../../../
