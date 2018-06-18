#!/bin/bash

module load launcher/3.2

set -u

IN_DIR=""
OUT_DIR=""
PARAMRUN="$TACC_LAUNCHER_DIR/paramrun"

export LAUNCHER_PLUGIN_DIR="$TACC_LAUNCHER_DIR/plugins"
export LAUNCHER_WORKDIR="$PWD"
export LAUNCHER_RMI="SLURM"
export LAUNCHER_SCHED="interleaved"

function lc() {
    FILE=$1
    [[ -f "$FILE" ]] && wc -l "$FILE" | cut -d ' ' -f 1
}

function USAGE() {
    printf "Usage:\\n  %s -i IN_DIR -o OUT_DIR\\n\\n" "$(basename "$0")"

    echo "Required arguments:"
    echo " -i IN_DIR (Cyverse DataStore directory)"
    echo " -o OUT_DIR (Cyverse DataStore directory)"
    exit "${1:-0}"
}

[[ $# -eq 0 ]] && USAGE 1

while getopts :i:o:h OPT; do
    case $OPT in
        i)
            IN_DIR="$OPTARG"
            ;;
        h)
            USAGE
            ;;
        o)
            OUT_DIR="$OPTARG"
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument."
            exit 1
            ;;
        \?)
            echo "Error: Invalid option: -${OPTARG:-""}"
            exit 1
    esac
done

if [[ -z "$IN_DIR" ]]; then
    echo "-i IN_DIR is required"
    exit 1
fi

if [[ -z "$OUT_DIR" ]]; then
    echo "-o OUT_DIR is required"
    exit 1
fi

FILES=$(mktemp)
if [[ -d "$IN_DIR" ]]; then
    echo "Will use local dir \"$IN_DIR\""
    find "$IN_DIR" -type f > "$FILES"
else
    TMP_DIR=$(mktemp -d -p "$SCRATCH")
    echo "TMP_DIR \"$TMP_DIR\""
    cd "$TMP_DIR" || exit

    echo "Getting $IN_DIR"
    iget -r "$IN_DIR"
    find . -type f > "$FILES"
fi

NUM_FILES=$(lc "$FILES")
echo "Found NUM_FILES \"$NUM_FILES\""

[[ $NUM_FILES -lt 1 ]] && exit

PARAM="$$.param"

imkdir "$OUT_DIR"

i=0
while read -r FILE; do
    i=$((i+1))
    printf "%3d: %s\\n" $i "$(basename "$FILE")"
    echo "$PWD/process.sh $FILE $OUT_DIR" >> "$PARAM"
    break
done < "$FILES"

cat -n "$PARAM"

LAUNCHER_JOB_FILE="$PARAM"
NUM_JOBS=$(lc "$PARAM")

if [[ $NUM_JOBS -gt 16 ]]; then
    LAUNCHER_PPN=16
else
    LAUNCHER_PPN=$NUM_JOBS
fi

export LAUNCHER_JOB_FILE
export LAUNCHER_PPN
$PARAMRUN
echo "Ended LAUNCHER $(date)"
rm "$PARAM"

echo "Done."
