#!/bin/sh

cd $TARGET_DIR
gpg --decrypt $1 | tar x

