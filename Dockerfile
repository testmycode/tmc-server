FROM ruby:2.3
LABEL name tmc-server

RUN \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/postgresql.list && \
  echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/webupd8team-java.list && \
  echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >> /etc/apt/sources.list.d/webupd8team-java.list && \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs vim lsof wget libfreetype6 libfontconfig bzip2 libfreetype6 libfontconfig bzip2 zip oracle-java8-installer postgresql-client-9.4 check && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer


ENV PHANTOMJS_VERSION 2.1.1

RUN wget --no-check-certificate -O /tmp/phantomjs.tar.bz2  https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
  tar -xjf /tmp/phantomjs.tar.bz2 -C /tmp && \
  rm -f /tmp/phantomjs.tar.bz2 && \
  mkdir -p /srv/var && \
  mv /tmp/phantomjs* /srv/var/phantomjs && \
  ln -s /srv/var/phantomjs/bin/phantomjs /usr/bin/phantomjs

ENV MAVEN_VERSION 3.3.9

RUN mkdir -p /usr/share/maven \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

RUN \
  git clone https://github.com/testmycode/tmc-check.git && \
  cd tmc-check && \
  bundle install --jobs=3 --retry=3 --deployment && \
  make && \
  make install

ENV MAVEN_HOME /usr/share/maven
ENV M3_HOME /usr/share/maven
RUN mkdir /app

WORKDIR /app

RUN git config --global user.name "TmcTest" && \
    git config --global user.email "tmc@example.com"
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install --system
ADD . /app

