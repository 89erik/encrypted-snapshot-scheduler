#!/bin/bash

# Creates an encrypted tar of the given backup directory, 
# if the directory has changed since the last backup.

if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo First argument must be password file!
    echo Second and third are content dir and backup dir,
    echo both optional and defaults to current directory.
    echo "Fourth argument is how many backups to keep (default 10)."
    echo "Use this command to decrypt: gpg --decrypt file.tar.gpg > file.tar"
    exit 1
fi

id=$(date +%F_%H%M)
content_dir="$2"
backup_dir="$3"
: ${content_dir:=.}
: ${backup_dir:=.}

if [[ ! -d "$content_dir" ]]; then
    echo "content source dir is not a directory: $content_dir"
    exit 1
fi

if [[ ! -d "$backup_dir" ]]; then
    echo "backup target dir is not a directory: $backup_dir"
    exit 1
fi

keep=10
if [[ $4 =~ ^[0-9]+$ ]] && [ $4 -gt 0 ] ; then
    keep=$4
fi
content_dir=$(readlink -e "$content_dir")
backup_dir=$(readlink -e "$backup_dir")

backup_file_basename="$(basename "$(readlink -e "$content_dir")")"
backup_file_basename=${backup_file_basename// /_}
backup_file="$backup_dir/${backup_file_basename}_${id}.tar.gpg"

previous_hash="/tmp/$(echo ${content_dir//\//.} | cut -c 2-).previous_backup_hash"
current_hash="$content_dir/.latest_backup_hash"

#######################

function create_hash {
    echo Hashing...
    cd "$content_dir"
    mv "$current_hash" "$previous_hash" 2> /dev/null
    touch .backup_history.txt
    mv .backup_history.txt /tmp
    files=$(find "$content_dir" -type f -exec md5sum {} \; | sort -k 2)
    echo $files | md5sum > "$current_hash"
    mv /tmp/.backup_history.txt .
    echo Done hashing
}

function cleanup_and_exit {
    rm -f "$previous_hash" 2> /dev/null
    exit $1
}

#######################

create_hash
diff "$current_hash" "$previous_hash" 2> /dev/null
if [ $? -eq 0 ]; then
    echo "No changes since last backup, exiting..."
    cleanup_and_exit 0
fi

echo Backing up \"$content_dir\" into \"$backup_file\" using password from \"$1\"

echo $content_dir $id >> "$content_dir/.backup_history.txt"

tar cpf - "$content_dir" | gpg --batch --yes --passphrase-file "$1" --symmetric --cipher-algo aes256 -o "$backup_file"
rc=$?
echo "Done. rc=$rc"

cd "$backup_dir"
for file in `ls ${backup_file_basename}_*.tar.gpg | sort -r`; do
    if [ $((keep--)) -le 0 ]; then
        echo Deleting \"$file\"
        rm $file
    fi
done

cleanup_and_exit $rc

