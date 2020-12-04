#!/bin/bash
set -eu

cmd=$*

# echo "Waiting for postgres..."
# until psql -h "$DB_HOST" -p 5432 -U "postgres" -c '\l' 2> /dev/null; do
#   >&2 echo -n "."
#   sleep 1
# done
# echo ""
if [ ! -z "$cmd" ]; then
  echo Running "$cmd"
  exec $cmd
fi