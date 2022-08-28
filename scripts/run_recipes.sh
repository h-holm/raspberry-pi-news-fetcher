#!/bin/bash
# Script to fetch news from sources specified in $RECIPES array using Calibre's 'ebook-convert' CLI command.

declare -a RECIPES=("The Economist" "Le Monde" "Zeit Online" "Spiegel Online RSS - German alle Themen")
FETCHED_NEWS_FOLDER="fetched-news"

timestamp=$(date +%Y-%m-%d-%H%M)
echo "Timestamp: $timestamp"

for recipe in "${RECIPES[@]}"; do
  echo
  echo "Fetching news from $recipe..."
  output_name="$recipe-$timestamp.epub"
  echo "File output name will be $output_name"

  # ebook-convert $recipe $output_name # Uses locally stored recipe.
  echo "Using command 'ebook-convert \"$recipe.recipe\" \"$output_name\"'"
  ebook-convert "$recipe.recipe" "$output_name" # Uses latest recipe shipped with calibre version you're using.
  sleep 3

  mv "$output_name" "$FETCHED_NEWS_FOLDER/"
  echo "Moved $output_name to $FETCHED_NEWS_FOLDER"
done
