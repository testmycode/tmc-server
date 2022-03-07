FROM eu.gcr.io/moocfi-public/tmc-server-base:latest
LABEL name tmc-server

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install --system --gemfile /app/Gemfile
RUN apt-get update
RUN apt-get -y install curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get -y install nodejs
ADD . /app
