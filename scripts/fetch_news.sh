#!/usr/bin/env bash
# Script to (1) fetch news from sources specified line-by-line in $SOURCES_FILE input argument using
# Calibre's `ebook-convert` CLI command, and (2) output resulting epub files to $OUTPUT_DIR.

print_help_message() {
	cat <<-EOF
			This script scrapes news from the sources listed in the file specified by the --sources-file
			flag and saves them in the output folder specified by the --output-dir flag.
	EOF
	echo
	cat <<-EOF
			Usage: fetch_news
			    [ -o | --output-dir ]
			    [ -s | --sources-file ]
			    [ -h | --help ]"
	EOF
}

SHORT_OPTS=f:,n:,h
LONG_OPTS=output-dir:,sources-file:,help
OPTS=$(getopt --options $SHORT_OPTS --longoptions $LONG_OPTS --name fetch_news.sh -- "$@")

# Returns the count of arguments that are in short or long options
VALID_ARGUMENTS=$#

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
	print_help_message
	exit 2
fi

eval set -- "$OPTS"

while [ $# -ge 1 ]; do
	case "$1" in
		-o | --output-dir )
			OUTPUT_DIR="$2"
			shift 2
			;;
		-s | --sources-file )
			SOURCES_FILE="$2"
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

if [ ! -f "$SOURCES_FILE" ]; then
    echo "No file found at value specified by --sources-file. Please provide the path to an existing file. Exiting..."
	exit 2
else
	readarray -t SOURCES < $SOURCES_FILE
	if [ ${#SOURCES[@]} -eq 0 ]; then
		echo "The provided --sources-file is empty. Please specify the path to a line-by-line file of valid Calibre news sources. Exiting..."
		exit 2
	fi
fi
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "No directory found at value specified by --output-dir. Please provide the path to an existing directory. Exiting..."
	exit 2
fi

echo "Starting script <fetch_news.sh> at $(date)."
echo "Considering the following news sources: ${SOURCES[@]}."
echo "Scraped epubs will be stored to directory '$OUTPUT_DIR'."

timestamp=$(date +%Y-%m-%d-%H%M)

for recipe in "${SOURCES[@]}"; do
	echo
	echo "Fetching news from $recipe..."
	output_name="$recipe-$timestamp.epub"
	echo "File output name will be $output_name"

	# echo "Using command 'ebook-convert \"$recipe\" \"$output_name\"'"
	# ebook-convert $recipe $output_name # Uses locally stored recipe.

	echo "Using command 'ebook-convert \"$recipe.recipe\" \"$output_name\"'"
	ebook-convert "$recipe.recipe" "$output_name" # Uses latest recipe shipped with calibre version you're using.

	sleep 3

	mv "$output_name" "$OUTPUT_DIR/"
	echo "Moved $output_name to $OUTPUT_DIR"
done

echo "Script <fetch_news.sh> completed at $(date)."