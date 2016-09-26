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

echo "Cleaning customizations for hermetic stable test setup"
rm -f config/site.yml
echo "Fixing site.yml for test"
sed -i 's/\(baseurl_for_remote_sandboxes:\).*/\1 '"$HOST"'/' config/site.defaults.yml

echo "Running migrations and starting tests"

if [ ! -z $REPORT_URL ]; then
  bundle exec rake db:create db:migrate spec SPEC_OPTS="--pattern $RSPEC_PATTERN --tag ~network --format RspecRemoteFormatter "
else
  bundle exec rake db:create db:migrate spec SPEC_OPTS="--pattern $RSPEC_PATTERN --tag ~network -f d "
fi
