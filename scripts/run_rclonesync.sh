#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# Run rclonesync command to sync local Dropbox folder with remote bidirectionally.

REMOTE_NAME=dropbox-books-henrik
REMOTE_FOLDER=dropbox_books
LOCAL_FOLDER=$HOME/dropbox-books-henrik

echo "Running run_clonesync.sh..."
echo "REMOTE_NAME: $REMOTE_NAME"
echo "REMOTE_FOLDER: $REMOTE_FOLDER"
echo "LOCAL_FOLDER: $LOCAL_FOLDER"

rclonesync --verbose $REMOTE_NAME:/$REMOTE_FOLDER $LOCAL_FOLDER
