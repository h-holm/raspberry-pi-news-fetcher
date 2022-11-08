#!/usr/bin/env bash
# Script to run the `rclonesync` command to bidirectionally sync a local Dropbox folder (as
# specified by the input --local-dropbox-dir option) and a remote Dropbox folder (as specified
# by the input --remote-dropbox-dir option).

print_help_message() {
	cat <<-EOF
			This script runs the 'rclonesync' command to bidirectionally sync a local Dropbox folder
			(as specified by the input --local-dropbox-dir flag) and a remote Dropbox folder (as
			specified by the input --remote-dropbox-dir flag) that exists on the 'rclone' remote
			specified by the input --remote-name flag. Note that this script requires 'rclone' and
			'rclonesync' to be installed and configured.
	EOF
	echo ""
	cat <<-EOF
			Usage: housekeep_news
			    [ -l | --local-dropbox-dir ]
			    [ -n | --remote-name ]
			    [ -r | --remote-dropbox-dir ]
			    [ -h | --help ]
	EOF
}

SHORT_OPTS=l:,n:,r:,h
LONG_OPTS=local-dropbox-dir:,remote-name:,remote-dropbox-dir:,help
OPTS=$(getopt --options $SHORT_OPTS --longoptions $LONG_OPTS --name run_rclonesync.sh -- "$@")

# Returns the count of arguments that are in short or long options
VALID_ARGUMENTS=$#

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
	print_help_message
	exit 2
fi

eval set -- "$OPTS"

while [ $# -ge 1 ]; do
	case "$1" in
		-l | --local-dropbox-dir )
			LOCAL_DROPBOX_DIR="$2"
			shift 2
			;;
		-n | --remote-name )
			REMOTE_NAME="$2"
			shift 2
			;;
		-r | --remote-dropbox-dir )
			REMOTE_DROPBOX_DIR="$2"
			shift 2
			;;
		-h | --help )
			print_help_message
			exit 2
			;;
		--)
			# No more options left.
			shift;
			break
			;;
		*)
			echo "Unexpected option: $1"
			print_help_message
			exit 2
			;;
	esac
done

if ! command -v rclonesync &> /dev/null
then
    echo "The 'rclonesync' command does not appear to be installed. Please make sure it is installed before running this script."
    exit
fi
if [ ! -d "$LOCAL_DROPBOX_DIR" ]; then
    echo "No directory found at value specified by --LOCAL_DROPBOX_DIR. Please provide the path to an existing directory. Exiting..."
	exit 2
fi

echo "Starting script <run_rclonesync.sh> at $(date)."
echo "The local Dropbox directory is set to: '$LOCAL_DROPBOX_DIR'."
echo "The Dropbox remote is set to: '$REMOTE_NAME'."
echo "The remote Dropbox directory is set to: '$REMOTE_DROPBOX_DIR'."

echo "Running command 'rclonesync --verbose $REMOTE_NAME:/$REMOTE_FOLDER $LOCAL_FOLDER':"
rclonesync --verbose $REMOTE_NAME:/$REMOTE_FOLDER $LOCAL_FOLDER
echo "Script <run_rclonesync.sh> completed at $(date)."