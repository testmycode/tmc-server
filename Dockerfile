FROM eu.gcr.io/moocfi-public/tmc-server-base:latest
LABEL name=tmc-server

RUN apt-get update \
  && apt-get -y install curl gnupg nodejs \
  && rm -rf /var/lib/apt/lists/*

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle config set path.system true \
  && bundle install --gemfile /app/Gemfile

ADD . /app
