# Encrypted snapshot scheduler

_Light-weight docker image that creates encrypted snapshots of one more directories whenever they change._

Configure it with a [cron schedule](https://crontab.guru/), a set of directories, a password, and an amount of versions to keep, and it will keep versioned and encrypted [tarballs](https://en.wikipedia.org/wiki/Tar_(computing)) of every directory that are safe to sync to an untrusted off-site server.

## Examples
### Minimal configuration
_Snapshot every user directory to an external disk every night, and encrypt with a bad password._
```sh
docker run \
  -v "/home:/source:ro" \
  -v "/media/backup_disk/:/target" \
  -e PASSWORD="password123" \
  encrypted_snapshot_scheduler
```

### Exhaustive configuration
_Snapshots every user directory, and a music and movies directory on an external drive, to another external drive at 0230 the first monday of every month CEST, and encrypt with a bad password._
```sh
docker run \
  -v /home/:/user_dirs:ro \
  -v /media/external_disk/:/external_disk:ro \
  -v /media/backup_disk/:/backup_disk \
  -e SOURCE_DIRS"/user_dirs/* /external_disk/music external_disk/movies" \
  -e TARGET_DIR=/backup_disk \
  -e CRON_EXPRESSION="30 2 1-7 * MON" \
  -e PASSWORD="password123" \
  -e TZ="Europe/Oslo" \
  --name=snapshot_home_and_media \
  encrypted_snapshot_scheduler:latest
```

## Environment variables

Configuration is done with the following environment variables

| Variable         | Description | Default value |
|.-----------------|-------------|---------------|
| CRON\_EXPRESSION | [cron expression](https://crontab.guru/) defining the schedule period  | 0 1 \* \* \* |
| SOURCE\_DIRS     | Space separated list of directories to back up. May include [glob patterns](https://en.wikipedia.org/wiki/Glob_(programming)). | /source/\* |
| TARGET\_DIR      | Directory to put the resulting tarballs     | /target     |
| N\_VERSIONS      | How many versions of each directory to keep | 1           |
| PASSWORD         | The password to encrypt the tarballs with   |             |
| TZ               | Timezone                                    | Europe/Oslo |


## Restoring
Restoring the tarballs can be done with the restore.sh script
```sh
# by piggy-backing the existing container
docker exec -it <name of container> /restore.sh my-backed-up-directory_2020-01-01_1200.tar.gpg

# or by launching a new one
docker run -it --rm -v "/media/backup_disk:/target" backupmaker /restore.sh my-backed-up-directory_2020-01-01_1200.tar.gpg

# or on your host machine in a terminal with tar and gpg installed
gpg --decrypt my-backed-up-directory_2020-01-01_1200.tar.gpg | tar x
```


## How it works
It uses cron to fire the backup task at a given interval. When this fires, for every one of the source directories, the directory is hashed and compared with the previous hash to determine if anything has change since last time. If the directory has changed, it is tar-ed and then encrypted using [GnuPG](https://gnupg.org/) with [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) 256 encryption with your provided password as key. Each directory is thus reduced to one file, whose name would be something like full-path-to-directory\_2020-01-01\_1200.tar.gpg. Eventually, when the amount of backup files for a directory exceeds N\_VERSIONS, the oldest are deleted so that only N versions of each directory is kept.

## Motivation
This program solves two problems: Preventing data loss because of disk failure, and preventing data loss because you accidentally deleted or destroyed a file.

Disk failures are remedied by configuring the target directory to another disk than the source directories. For increased protection, this directory should also be synced to an offsite server. Because this directory will only contain encrypted files, you don't necessarily have to trust the owner of the offsite server to keep your files private.

Accidentally deleting files are remedied by keeping several versions of the backup. Set N\_VERSION as high as you can afford (keeping in mind a full-sized backup is created every time the source directory changes), so if you accidentally delete something and don't notice straight away, you can still retrieve it.


