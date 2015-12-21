# Pull base image.
FROM ubuntu:14.04.3

# apt-add-repository
RUN apt-get install -y software-properties-common
# Install Java.
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle


## INSTALL RUBY ##

RUN apt-get update && apt-get install -y --no-install-recommends \
                autoconf \
                automake \
                bzip2 \
                check \
                zip \
                unzip \
                file \
                g++ \
                gcc \
                imagemagick \
                libbz2-dev \
                libc6-dev \
                libcurl4-openssl-dev \
                libevent-dev \
                libffi-dev \
                libgeoip-dev \
                libglib2.0-dev \
                libjpeg-dev \
                liblzma-dev \
                libmagickcore-dev \
                libmagickwand-dev \
                libncurses-dev \
                libpng-dev \
                libpq-dev \
                libreadline-dev \
                libsqlite3-dev \
                libssl-dev \
                libtool \
                libwebp-dev \
                libxml2-dev \
                libxslt-dev \
                libyaml-dev \
                make \
                maven \
                patch \
                pkg-config \
                xz-utils \
                zlib1g-dev \
                curl \
                git \
      && rm -rf /var/lib/apt/lists/*

ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.4
ENV RUBY_DOWNLOAD_SHA256 b6eff568b48e0fda76e5a36333175df049b204e91217aa32a65153cc0cdcb761
ENV RUBYGEMS_VERSION 2.5.1

# skip installing gem documentation
RUN echo 'install: --no-document\nupdate: --no-document' >> "$HOME/.gemrc"

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get update \
        && apt-get install -y bison libgdbm-dev ruby \
        && rm -rf /var/lib/apt/lists/* \
        && mkdir -p /usr/src/ruby \
        && curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
        && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
        && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
        && rm ruby.tar.gz \
        && cd /usr/src/ruby \
        && autoconf \
        && ./configure --disable-install-doc \
        && make -j"$(nproc)" \
        && make install \
        && apt-get purge -y --auto-remove bison libgdbm-dev ruby \
        && gem update --system $RUBYGEMS_VERSION \
        && rm -r /usr/src/ruby

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

ENV BUNDLER_VERSION 1.11.2

RUN gem install bundler --version "$BUNDLER_VERSION" \
        && bundle config --global path "$GEM_HOME" \
        && bundle config --global bin "$GEM_HOME/bin"

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

RUN git config --global user.name "tmc" \
  && git config --global user.email "tmc@example.com"

RUN mkdir /tmc-server
WORKDIR /tmc-server
ADD Gemfile /tmc-server/Gemfile
ADD Gemfile.lock /tmc-server/Gemfile.lock
RUN bundle install
ADD . /tmc-server
