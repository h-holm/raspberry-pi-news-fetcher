#!/usr/bin/env bash
# Script to fetch news from the sources specified line-by-line in the `--sources-file`
# file by running Calibre's `ebook-convert` CLI command and to output the resulting
# EPUB files to the `--output-dir`.

set -e

PROGRAM_NAME="fetch_news.sh"

function usage {
  echo "This script scrapes news from the sources listed line-by-line in the" \
    '`--sources-file` file by running the `ebook-convert` command of the Calibre' \
    'CLI. The script saves the resulting EPUB files to the `--output-dir` directory.'
  echo
  echo "Usage: $PROGRAM_NAME [ -s | --sources-file ] [ -o | --output-dir ]"
  echo "  -s | --sources-file   Path to line-by-line listing of Calibre news sources."
  echo "  -o | --output-dir     Path to output directory."
  echo "  -h | --help           Display this help message."
}

SHORT_OPTS=s:,o:,h
LONG_OPTS=sources-file:,output-dir:,help
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
    -o | --output-dir )
      # Remove trailing slashes.
      OUTPUT_DIR=$(echo "$2" | sed 's:/*$::')
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

if [ ! command -v ebook-convert &> /dev/null ]; then
  echo "The 'ebook-convert' command is required by this script but could not"\
    "be found. Please install the Calibre CLI before running this script."
  exit 2
fi
if [ ! -f "${SOURCES_FILE}" ]; then
  echo "No file found at value specified by --sources-file. Please provide"\
    "the path to an existing file. Exiting..."
  exit 2
else
  readarray -t SOURCES < ${SOURCES_FILE}
  if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "The provided --sources-file is empty. Please specify the path to a"\
      "line-by-line file of valid Calibre news sources. Exiting..."
    exit 2
  fi
fi
if [ ! -d "${OUTPUT_DIR}" ]; then
  mkdir -p "${OUTPUT_DIR}"
  echo "Created directory '${OUTPUT_DIR}' as it did not already exist."
fi

echo "Starting script <$PROGRAM_NAME> at $(date)."
echo "Considering the following news sources: ${SOURCES[@]}."
echo "Scraped EPUBs will be stored to directory: '${OUTPUT_DIR}'."

timestamp=$(date +%Y-%m-%d-%H%M)

failures=""
for SRC in "${SOURCES[@]}"; do
  # Decide whether to use a local `.recipe` file stored under `./recipes/` or a recipe
  # built-in to / shipped with Calibre.
  if [ -f "recipes/${SRC}.recipe" ]; then
    recipe="recipes/${SRC}.recipe"
  else
    if ebook-convert --list-recipes |& grep -q "${SRC}"; then
      recipe="${SRC}.recipe"
    else
      echo "No recipe for source '${SRC}' was found among Calibre's built-in" \
        "recipes, nor locally in the \`./recipes\` directory. Skipping '${SRC}'..."
      continue
    fi
  fi

  echo
  echo "Fetching news from '${SRC}'..."
  output_name="${SRC}-$timestamp.epub"
  echo "File output name set to: '${output_name}'"

  echo "Using command \`ebook-convert \"$recipe\" \"${OUTPUT_DIR}/${output_name}\"\`"
  {  # try
    ebook-convert "$recipe" "${OUTPUT_DIR}/${output_name}" \
      && sleep 3 \
      && echo "Successfully fetched news from '${SRC}'!"
  } || {  # catch
    echo "Fetching of news from '${SRC}' failed!" \
      && failures+=$'\n'"- ${SRC}"
  }

done

# Log any failures.
if [ -z "${failures}" ]; then
  # Strip off leading and trailing whitespace.
  failures=$(echo "${failures}" | xargs)
  echo "The following news sources could not be successfully scraped:"
  echo "${failures}"
fi

echo "Script <$PROGRAM_NAME> completed at $(date)."
