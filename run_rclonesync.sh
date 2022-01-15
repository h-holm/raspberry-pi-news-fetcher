#!/usr/bin/env bash
# Run rclonesync command to sync local Dropbox folder with remote bidirectionally.

REMOTE_NAME=dropbox-books-henrik
REMOTE_FOLDER=dropbox_books
LOCAL_FOLDER=$HOME/dropbox-books-henrik

rclonesync --verbose $REMOTE_NAME:/$REMOTE_FOLDER $LOCAL_FOLDER
