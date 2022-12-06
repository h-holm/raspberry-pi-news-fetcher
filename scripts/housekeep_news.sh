#!/usr/bin/env bash
# This script 'housekeeps' news epubs stemming from the sources listed in the
# file specified by the --sources-file flag by (1) moving new epubs from the
# --from-dir to the --target-dir ("new" here meaning epubs that do not already
# exist in the --target-dir), and (2) removing epubs from --from-dir and
# --target-dir that are older than --max-num-days.

PROGRAM_NAME="housekeep_news.sh"

function usage {
  echo "This script 'housekeeps' news epubs stemming from the sources listed"\
    "in the file specified by the --sources-file flag by (1) moving new epubs"\
    "from the --from-dir to the --target-dir (\"new\" here meaning epubs that"\
    "do not already exist in the --target-dir), and (2) removing epubs from"\
    "--from-dir and --target-dir that are older than --max-num-days."
  echo ""
  echo "Usage: $PROGRAM_NAME [ -s | --sources-file ] [ -f | --from-dir ]"\
    "[ -t | --target-dir ] [ -m | --max-num-days ]"
  echo "  -s | --sources-file   Path to line-by-line file of news sources."
  echo "  -f | --from-dir       Path to directory to move epubs from."
  echo "  -t | --target-dir     Path to directory to move epubs to."
  echo "  -m | --max-num-days   Maximum age (in days) of epubs to keep."
  echo "  -h | --help           Display this help message."
}

SHORT_OPTS=s:,f:,t:,m:,h
LONG_OPTS=sources-file:,from-dir:,target-dir:,max-num-days:,help
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
    -s | --sources-file )
      SOURCES_FILE="$2"
      shift 2
      ;;
    -f | --from-dir )
      FROM_DIR="$2"
      shift 2
      ;;
    -t | --target-dir )
      TARGET_DIR="$2"
      shift 2
      ;;
    -m | --max-num-days )
      MAX_NUM_DAYS="$2"
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

if [ ! -f "$SOURCES_FILE" ]; then
  echo "No file found at value specified by --sources-file. Please provide"\
    "the path to an existing file. Exiting..."
  exit 2
else
  readarray -t SOURCES < $SOURCES_FILE
  if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "The provided --sources-file is empty. Please specify the path to a"\
      "line-by-line file of valid Calibre news sources. Exiting..."
    exit 2
  fi
fi
if [ ! -d "$FROM_DIR" ]; then
  echo "No directory found at value specified by --from-dir. Please provide"\
    "the path to an existing directory. Exiting..."
  exit 2
fi
if [ ! -d "$TARGET_DIR" ]; then
  echo "No directory found at value specified by --target-dir. Please provide"\
    "the path to an existing directory. Exiting..."
  exit 2
fi
if [ ! "$MAX_NUM_DAYS" -gt 0 ]; then
  echo "$MAX_NUM_DAYS is not a valid --max-num-days value. Please provide a"\
    "number greater than 0. Exiting..."
  exit 2
fi

echo "Starting script <$PROGRAM_NAME> at $(date)."
echo "Considering the following news sources: ${SOURCES[@]}."
echo "Searching for new epubs in directory '$FROM_DIR', which will also be cleaned."
echo "New epubs will be moved to directory '$TARGET_DIR', which will also be cleaned."
echo "Epubs older than $MAX_NUM_DAYS days will be deleted."

# If needed, you could alternatively use -print0 to handle paths containing spaces.
to_copy_array=()
for source in "${SOURCES[@]}"; do
  find "$TARGET_DIR" -name "*$source*" -mtime +$MAX_NUM_DAYS -type f -print -exec rm -rv "{}" \;
  find "$FROM_DIR" -name "*$source*" -mtime +$MAX_NUM_DAYS -type f -print -exec rm -rv "{}" \;
  while IFS=  read -r -d $'\0'; do
    to_copy_array+=("$REPLY")
  done < <(find "$FROM_DIR" -name "*$source*.epub" -type f -print0)
done

# Use the -n flag to not overwrite existing.
if (( ${#to_copy_array[@]} != 0 )); then
  cp -n -v "${to_copy_array[@]}" "$TARGET_DIR"
fi
echo "Copied ${#to_copy_array[@]} epubs to $TARGET_DIR."

echo "Script <$PROGRAM_NAME> completed at $(date)."
