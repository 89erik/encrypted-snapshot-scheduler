#!/bin/bash

# Backs up every sub directory in given parent source directory, 
# except dirs mentioned in .backupignore in said directory.
# Keeps only one backup file per sub dir.

cd "$(dirname "${BASH_SOURCE[0]}")"

function exit_helpfully {
    echo Error in argument $1! Expects arguments:
    echo "  1. Password file"
    echo "  2. Parent source directory"
    echo "  3. Target directory"
    exit 1
}



if [ -z "$1" ] || [ ! -f $1 ]; then
    exit_helpfully 1
fi
if [ -z "$2" ] || [ ! -d $2 ]; then
    exit_helpfully 2
fi
if [ -z "$3" ] || [ ! -d $3 ]; then
    exit_helpfully 3
fi

pw_file=$1
src_dir=$2
tgt_dir=$3


function not_ignored {
    if [ -f $src_dir/.backupignore ]
    then
        if grep "$(basename "$1")" $src_dir/.backupignore > /dev/null
        then
            echo "Ignoring $1"
            false
            return
        fi
    fi
    true
}

for d in $2/*
do
    if [ -d "$d" ] && not_ignored "$d"
    then
        echo "Starting $d"
        ./backup.sh "$pw_file" "$d" "$tgt_dir" 1
        echo
        echo "######################################"
    fi
done

