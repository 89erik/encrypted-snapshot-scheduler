#!/bin/sh

for d in $SOURCE_DIRS
do
    if [ -d "$d" ]
    then
        echo "Starting $d"
        /backup.sh "$PASSWORD" "$d" "$TARGET_DIR" $N_VERSIONS
        echo
        echo "######################################"
    fi
done

