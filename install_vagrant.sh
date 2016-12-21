#!/bin/bash

set -eu pipefail

echo 'Installing dependencies...'
apt-get update
apt-get install -y git build-essential zip unzip imagemagick maven make phantomjs bc postgresql postgresql-contrib chrpath libssl-dev libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev xfonts-75dpi libpq-dev git-core curl zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev libgdbm-dev libncurses5-dev automake libtool bison libffi-dev squashfs-tools multistrap e2fsprogs e2tools wkhtmltopdf ruby ruby-dev ruby-bundler check debian-keyring debian-archive-keyring
echo 'Installing Java...'
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
apt-get install -y oracle-java8-installer oracle-java8-set-default
# echo 'Installing rvm...'
# gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
# curl -L https://get.rvm.io | sudo bash -s stable
# export rvm_path=/usr/local/rvm
# echo 'Sourcing rvm...'
# #source /etc/profile.d/rvm.sh
# usermod -a -G rvm ubuntu
# echo 'Installing Ruby...'
# rvm install 2.2.0
# echo 'Magic'
# source $(rvm 2.2.0 do rvm env --path)
# echo 'Setting the default Ruby...'
# sudo -u ubuntu /usr/local/rvm/bin/rvm use 2.2.0 --default
# echo 'Installing bundler...'
# gem install bundler

echo 'Configuring postgres...'
sudo -u postgres psql -c "CREATE ROLE tmc PASSWORD 'md54e71eeacea8051ce19dde0da34ca97c7' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;" || true
sed -i -e 's/local \+all \+all \+peer/local   all             all                                     md5/g' /etc/postgresql/9.5/main/pg_hba.conf
systemctl restart postgresql

echo 'Installing phantomjs'
wget --no-check-certificate -O /tmp/phantomjs.tar.bz2  https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
tar -xjf /tmp/phantomjs.tar.bz2 -C /tmp
rm -f /tmp/phantomjs.tar.bz2
mkdir -p /srv/var
mv /tmp/phantomjs* /srv/var/phantomjs
ln -s /srv/var/phantomjs/bin/phantomjs /usr/bin/phantomjs
echo 'done'
false

echo 'Installing deps'

exec sudo -u ubuntu /bin/bash - << eof
  set -eu pipefails
  cd /vagrant/
  echo 'Bundle install...'
  bundle install -j $(nproc)
  echo 'Initializing database...'
  bundle exec rake db:create db:migrate db:seed || true
  echo 'Updating submodules...'
  git submodule update --init --recursive

  echo 'Building tmc sandbox'
  cd ext/tmc-sandbox
  # vboxfs does not support hard links so we have to do this somewhere else
  mkdir -p /tmp/sandbox-build
  #sudo cp -R Makefile uml misc /tmp/sandbox-build
  #cd /tmp/sandbox-build
  #sudo make
  mkdir -p /vagrant/ext/tmc-sandbox/uml/output
  sudo rm -rf /tmp/sandbox-build/uml/output/tmc-check/.git || true
  sudo cp -r /tmp/sandbox-build/uml/output/{linux.uml,initrd.img,rootfs.squashfs,tmc-check} /vagrant/ext/tmc-sandbox/uml/output
  sudo cp -r /tmp/sandbox-build/misc/{dnsmasq,squidroot} /vagrant/ext/tmc-sandbox/misc
  echo 'Building sandbox web'
  cd /vagrant/ext/tmc-sandbox/web
  bundle install
  rake ext
  echo 'Building rest of sandbox externals'
  cd ..
  rake compile

  echo 'building tmc-check'
  cd uml/output/tmc-check
  sudo make rubygems install clean
eof
