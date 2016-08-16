#!/bin/bash
set -e

cmd="$@"

until psql -h "$DB_HOST" -p 5432 -U "postgres" -c '\l'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
if [ ! -z $cmd ]; then
 exec $cmd
fi
bundle exec rake db:create db:migrate spec SPEC_OPTS="--pattern $RSPEC_PATTERN --tag ~network --format RspecRemoteFormatter "
