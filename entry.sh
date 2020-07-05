#!/bin/sh

if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]
then
    echo "Expected TARGET_DIR to be a directory, it was: $TARGET_DIR"
    exit 1
fi

if [ -z "$PASSWORD" ]
then 
    echo "The PASSWORD environment variable is empty"
    exit 1
fi


echo "Will backup the following directories"
success=false
for dir in $SOURCE_DIRS
do
    if [ -d $dir ]
    then
        echo $dir
        success=true
    fi
done

if [ $success != "true" ]
then
    echo "The SOURCE_DIR environment variable did not resolve to any directories"
    exit 1
fi


echo "$CRON_EXPRESSION /backup_source_dirs.sh" > backupmaker.tab
crontab backupmaker.tab

echo Using the following crontab:
cat backupmaker.tab

crond -f

