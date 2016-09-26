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

/app/script/background_daemon run &
rails s -b 0.0.0.0 --pid=/tmp/dev.pid

