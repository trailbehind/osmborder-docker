#!/bin/bash
set -e -u

URL="${URL:-http://ftp.osuosl.org/pub/openstreetmap/pbf/planet-latest.osm.pbf}"
STORAGE_DIR="${STORAGE_DIR:-.}"
OSM_FILE=$STORAGE_DIR/`basename $URL`
OUTPUT_FILE="${OUTPUT_FILE:-$STORAGE_DIR/osmborder_lines.csv}"

if [[ ! -e ${OSM_FILE} ]]; then
    echo "Downloading planet-latest.osm.pbf to $OSM_FILE"
    wget -nv $URL.md5 -O $OSM_FILE.md5
    wget -nv $URL -O $OSM_FILE
fi

pushd $STORAGE_DIR
md5sum -c $OSM_FILE.md5
popd

echo "loading osm file with date '`osmium fileinfo -g 'header.option.osmosis_replication_timestamp' $OSM_FILE`'"
echo "outputing to $OUTPUT_FILE"

osmborder_filter -o $STORAGE_DIR/filtered.osm.pbf $OSM_FILE
osmborder -o $OUTPUT_FILE $STORAGE_DIR/filtered.osm.pbf

if [[ ! -z "$S3_LOCATION" ]]; then
    echo "Uploading to s3"
    aws s3 cp $OUTPUT_FILE $S3_LOCATION
fi
