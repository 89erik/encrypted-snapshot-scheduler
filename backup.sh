#!/bin/sh

# Creates an encrypted tar of the given backup directory, 
# if the directory has changed since the last backup.

if [ -z "$1" ]; then
    echo First argument is the encryption password
    echo Second and third are content dir and backup dir,
    echo both optional and defaults to current directory.
    echo "Fourth argument is how many backups to keep (default 10)."
    echo "Use this command to decrypt: gpg --decrypt file.tar.gpg > file.tar"
    exit 1
fi

id=$(date +%F_%H%M)
content_dir="$2"
backup_dir="$3"

if [[ ! -d "$content_dir" ]]; then
    echo "content source dir is not a directory: $content_dir"
    exit 1
fi

if [[ ! -d "$backup_dir" ]]; then
    echo "backup target dir is not a directory: $backup_dir"
    exit 1
fi

keep=10
if echo $4 | egrep -q '^[0-9]+$' && [ $4 -gt 0 ] ; then
    keep=$4
    echo keeping $keep versions
fi
content_dir=$(readlink -f "$content_dir")
backup_dir=$(readlink -f "$backup_dir")

backup_file_basename="$(readlink -f "$content_dir")"  # follow links
backup_file_basename=${backup_file_basename#/}        # remove leading slash
backup_file_basename=${backup_file_basename//\//-}    # slash to dash
backup_file_basename=${backup_file_basename// /_}     # space to underscore
backup_file="$backup_dir/${backup_file_basename}_${id}.tar.gpg"

mkdir -p /backup_hashes/
previous_hash="/backup_hashes/$backup_file_basename.previous_backup_hash"
current_hash="/backup_hashes/$backup_file_basename.latest_backup_hash"

#######################

function create_hash {
    echo Hashing...
    cd "$content_dir"
    mv "$current_hash" "$previous_hash" 2> /dev/null
    files=$(find "$content_dir" -type f -exec md5sum {} \; | sort -k 2)
    echo $files | md5sum > "$current_hash"
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

echo Backing up \"$content_dir\" into \"$backup_file\"

tar cpf - "$content_dir" | gpg --batch --yes --passphrase "$1" --symmetric --cipher-algo aes256 -o "$backup_file"
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

