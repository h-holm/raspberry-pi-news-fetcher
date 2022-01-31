#!/bin/bash

RECIPES_FOLDER="./recipes"
RECIPES="$RECIPES_FOLDER/*.recipe"

declare -A RECIPE_TO_SOURCE_HASHMAP
RECIPE_TO_SOURCE_HASHMAP["economist.recipe"]="The Economist"
RECIPE_TO_SOURCE_HASHMAP["faznet.recipe"]="FAZ"
RECIPE_TO_SOURCE_HASHMAP["lemonde_dip.recipe"]="Le Monde"
RECIPE_TO_SOURCE_HASHMAP["people_daily.recipe"]="人民日报"

timestamp=$(date +%Y-%m-%d-%H%M)
echo $timestamp

for recipe in $RECIPES
do
  recipe_stem=${recipe##*/}
  if [ "${RECIPE_TO_SOURCE_HASHMAP[$recipe_stem]+abc}" ]; then # Return 'abc' if key exists. https://stackoverflow.com/questions/13219634/easiest-way-to-check-for-an-index-or-a-key-in-an-array
    recipe_name=${RECIPE_TO_SOURCE_HASHMAP[$recipe_stem]}.recipe
  else
    recipe_name=$recipe_stem
  fi
  echo "Fetching news from $recipe_name..."
  output_name="$recipe_name-$timestamp.epub"
  echo "File output name will be $output_name"

  # ebook-convert $recipe $output_name # Uses locally stored recipe.
  echo "Using command 'ebook-convert \"$recipe_name\" \"$output_name\"'"
  ebook-convert "$recipe_name" "$output_name" # Uses latest recipe shipped with calibre version you're using.
  sleep 3
  # echo "Adding $recipe to
  echo
done
