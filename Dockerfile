FROM alpine:latest
RUN apk --update-cache add tzdata gnupg

COPY entry.sh backup_source_dirs.sh backup.sh /
CMD /entry.sh

ENV TZ=Europe/Oslo
ENV CRON_EXPRESSION="0 1 * * *"
ENV SOURCE_DIRS=/source/*
ENV TARGET_DIR=/target
ENV N_VERSIONS=1

