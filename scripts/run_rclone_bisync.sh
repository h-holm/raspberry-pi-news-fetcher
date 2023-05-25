#!/usr/bin/env bash
# This script runs the 'rclone bisync' command to bidirectionally sync a local
# Dropbox folder (specified by the --local-dropbox-dir flag) and a remote
# Dropbox folder (specified by the --remote-dropbox-dir flag) that exists on
# the 'rclone' remote specified by the --remote-name flag. Note that the script
# requires 'rclone' to be installed and configured.

set -e

PROGRAM_NAME="run_rclone_bisync.sh"

function usage {
  echo "This script runs the 'rclone bisync' command to bidirectionally sync"\
    "a local Dropbox folder (specified by the --local-dropbox-dir flag) and a"\
    "remote Dropbox folder (specified by the --remote-dropbox-dir flag) that"\
    "exists on the 'rclone' remote specified by the --remote-name flag. Note"\
    "that the script requires 'rclone' to be installed and configured."
  echo
  echo "Usage: $PROGRAM_NAME [ -l | --local-dropbox-dir ]"\
    "[ -r | --remote-dropbox-dir ] [ -n | --remote-name ]"
  echo "  -l | --local-dropbox-dir   Path to local copy of a Dropbox folder."
  echo "  -r | --remote-dropbox-dir  Name of the same Dropbox folder on the"\
    "configured 'rclone' remote specified by the --remote-name flag."
  echo "  -n | --remote-name         Name of the 'rclone' remote where the"\
    "--remote-dropbox-dir exists."
  echo "  -h | --help                Display this help message."
}

SHORT_OPTS=l:,r:,n:,h
LONG_OPTS=local-dropbox-dir:,remote-dropbox-dir:,remote-name:,help
OPTS=$(getopt --options $SHORT_OPTS --longoptions $LONG_OPTS --name $PROGRAM_NAME -- "$@")

# Returns the count of provided args that are in the short or long options.
VALID_ARGUMENTS=$#

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  usage
  exit 2
fi

eval set -- "$OPTS"

while [ $# -ge 1 ]; do
  case "$1" in
    -l | --local-dropbox-dir )
      LOCAL_DROPBOX_DIR="$2"
      shift 2
      ;;
    -r | --remote-dropbox-dir )
      REMOTE_DROPBOX_DIR="$2"
      shift 2
      ;;
    -n | --remote-name )
      REMOTE_NAME="$2"
      shift 2
      ;;
    -h | --help )
      usage
      exit 2
      ;;
    --)
      # No more options left.
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      usage
      exit 2
      ;;
  esac
done

if [ ! command -v rclone &> /dev/null ]; then
  echo "The 'rclone' command is required by this script but could not be"\
    "found. Please install and configure 'rclone' before running this script."
  exit 2
fi
if [ ! -d "$LOCAL_DROPBOX_DIR" ]; then
  echo "No directory found at path specified by --local-dropbox-dir. Please"\
    "provide the path to an existing directory. Exiting..."
  exit 2
fi

echo "Starting script <$PROGRAM_NAME> at $(date)."
echo "The local Dropbox directory is set to: '$LOCAL_DROPBOX_DIR'."
echo "The remote Dropbox directory is set to: '$REMOTE_DROPBOX_DIR'."
echo "The Dropbox remote is set to: '$REMOTE_NAME'."

echo "Running command 'rclone bisync --verbose --force \"$LOCAL_DROPBOX_DIR\" \"$REMOTE_NAME\":/\"$REMOTE_DROPBOX_DIR\"':"
rclone bisync --verbose --force "$LOCAL_DROPBOX_DIR" "$REMOTE_NAME":/"$REMOTE_DROPBOX_DIR"
echo "Script <$PROGRAM_NAME> completed at $(date)."
