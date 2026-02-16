#!/bin/bash

TRIES=3

cat queries.sql | while read -r query; do
    sync
    #echo 3 | sudo tee /proc/sys/vm/drop_caches

    echo "$query"
    (
        echo '\timing'
        yes "$query" | head -n $TRIES
    ) | psql -h localhost -p 6875 -U materialize -d materialize -t 2>&1 | grep -P 'Time|psql: error'
done
