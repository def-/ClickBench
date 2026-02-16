#!/bin/bash

set -eu

sudo apt-get update -y
sudo apt-get install -y docker.io pigz postgresql-client

# Start Materialize via Docker
sudo docker run -d --name materialize \
    -p 6875-6877:6875-6877 \
    materialize/materialized

# Wait for Materialize to be ready
sleep 5
until psql -h localhost -p 6875 -U materialize -d materialize -c 'SELECT 1' 2>/dev/null; do
    echo "Waiting for Materialize to start..."
    sleep 5
done

wget --continue --progress=dot:giga 'https://datasets.clickhouse.com/hits_compatible/hits.tsv.gz'
pigz -d -f hits.tsv.gz

psql -h localhost -p 6875 -U materialize -d materialize -t <create.sql 2>&1 | tee load_out.txt
if grep 'ERROR' load_out.txt
then
    exit 1
fi

echo -n "Load time: "
command time -f '%e' ./load.sh

./run.sh 2>&1 | tee log.txt

echo -n "Data size: "
sudo docker exec materialize du -bcs /mzdata/ 2>/dev/null | grep total || echo "N/A"

cat log.txt | grep -oP 'Time: \d+\.\d+ ms|psql: error' | sed -r -e 's/Time: ([0-9]+\.[0-9]+) ms/\1/; s/^.*psql: error.*$/null/' |
    awk '{ if (i % 3 == 0) { printf "[" }; if ($1 == "null") { printf $1 } else { printf $1 / 1000 }; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }'
