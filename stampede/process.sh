#!/bin/bash

set -u

if [[ $# -ne 2 ]]; then
    echo "usage: %s FILE OUT_DIR" "$(basename "$0")"
    exit 1
fi

FILE=$1
OUT_DIR=$2

echo "Processing \"$(basename "$FILE")\" => \"$OUT_DIR\""

EXT=${FILE##*.}

if [[ "$FILE" =~ .*\.(tar.gz|tar.bz|tgz|tar)$ ]]; then
    tar xvf "$FILE"
    rm "$FILE"
    NEW=$(echo "$FILE" | perl -pe 's/\.(tar.gz|tar.bz|tgz|tar)$//')
elif [[ $EXT == "gz" ]]; then
    gunzip "$FILE"
    NEW=$(basename "$FILE" ".$EXT")
elif [[ $EXT == "zip" ]]; then
    unzip "$FILE"
    rm "$FILE"
    NEW=$(basename "$FILE" ".$EXT")
elif [[ $EXT == "bz" ]] || [[ $EXT == "bz2" ]]; then
    bunzip2 "$FILE"
    NEW=$(basename "$FILE" ".$EXT")
else
    echo "FILE is not compressed"
    NEW="$FILE"
fi


echo iput "$NEW" "$OUT_DIR"
