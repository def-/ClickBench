#!/bin/bash

set -eu

PSQL="psql -h localhost -p 6875 -U materialize -d materialize"

split -C 900M hits.tsv hits_chunk_

for chunk in hits_chunk_*; do
    echo "Loading $chunk..."
    $PSQL -c "\copy hits FROM '$chunk'"
done

rm -f hits_chunk_*


echo "Creating default index on hits..."
$PSQL -c "CREATE DEFAULT INDEX ON hits"
