#!/usr/bin/env bash
# Script to fetch news from the sources specified line-by-line in the `--sources-file`
# file by running Calibre's `ebook-convert` CLI command and to output the resulting
# EPUB files to the `--output-dir`.

set -e

PROGRAM_NAME="fetch_news.sh"

# Set the default path to the directory of local recipe files (if any).
parent_dir="$(dirname "$(realpath "$0")")"
grandparent_dir="$(dirname "$parent_dir")"
RECIPES_DIR="${grandparent_dir}/recipes"

function usage {
  echo "This script scrapes news from the sources listed line-by-line in the" \
    '`--sources-file` file by running the `ebook-convert` command of the Calibre' \
    'CLI. The script saves the resulting EPUB files to the `--output-dir` directory.'
  echo
  echo "Usage: $PROGRAM_NAME [ -s | --sources-file ] [ -o | --output-dir ]"
  echo "  -s | --sources-file   Path to line-by-line listing of Calibre news sources."
  echo "  -o | --output-dir     Path to output directory."
  echo '  -r | --recipes-dir    Path to directory of local `.recipe` files to use.' \
    'For a given news source (e.g., "The Economist"), if the `--recipes-dir` contains' \
    'a valid `.recipe` file ("The Economist.recipe"), the local `.recipe` file takes' \
    'precedence over the corresponding built-in Calibre recipe (if any). Defaults to:' \
    "'${RECIPES_DIR}'."
  echo "  -h | --help           Display this help message."
}

function error {
  # Print an error message to stderr without exiting the script.
  echo "Error: $@" >&2
}

SHORT_OPTS=s:,o:,r:,h
LONG_OPTS=sources-file:,output-dir:,recipes-dir:,help
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
    -r | --recipes-dir )
      # If the `--recipes-dir` argument is specified, set the `RECIPES_DIR` variable to
      # the provided value. Otherwise, keep the default value.
      RECIPES_DIR=$(echo "$2" | sed 's:/*$::')
      if [ ! -d "${RECIPES_DIR}" ]; then
        echo 'The provided `--recipes-dir` is not the path to a valid directory:' \
          "'${RECIPES_DIR}' Exiting..."
        exit 2
      fi
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
echo "The (local) recipes directory is set to: '${RECIPES_DIR}'."

timestamp=$(date +%Y-%m-%d-%H%M)

failures=""
for SRC in "${SOURCES[@]}"; do
  echo

  # Decide whether to use (1) a local `.recipe` file stored under the `RECIPES_DIR`
  # directory or (2) a recipe built-in to / shipped with Calibre.
  local_recipe_file="${RECIPES_DIR}/${SRC}.recipe"
  echo "Checking whether a local recipe file exists at: '${local_recipe_file}'..."
  if [ -f "${local_recipe_file}" ]; then
    # If a local recipe file exists, use it.
    recipe="${RECIPES_DIR}/${SRC}.recipe"
    echo "Using local recipe file: '${recipe}'"
  else
    # Check if Calibre ships a built-in recipe for source "${SRC}". Note that the
    # `--list-recipes` command lists all available recipes, meaning that multiple lines
    # may match "${SRC}". To ensure a verbatim match, first strip off leading and
    # trailing whitespace from the output of the `ebook-convert` command. Then
    echo "Checking whether a Calibre built-in recipe exists for source '${SRC}'..."
    if ebook-convert --list-recipes |& awk '{$1=$1;print}' | grep --line-regexp --quiet "${SRC}"; then
      # If a built-in recipe exists, use it.
      recipe="${SRC}.recipe"
      echo "Using Calibre built-in recipe: '${recipe}'"
    else
      # If the recipe name is not found, skip to the next source.
      error "A recipe for source '${SRC}' was found neither among Calibre's built-in" \
        "recipes nor locally in the '${RECIPES_DIR}' directory. Skipping '${SRC}'..."
      failures+=$'\n'"- ${SRC}"
      continue
    fi
  fi

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
if [ "${failures}" ]; then
  # Strip off leading and trailing whitespace.
  failures=$(echo "${failures}" | xargs)
  echo "The following news sources could not be successfully scraped:"
  echo "${failures}"
fi

echo "Script <$PROGRAM_NAME> completed at $(date)."
