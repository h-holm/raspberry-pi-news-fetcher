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
  echo $recipe
  recipe_stem=${recipe##*/}
  echo $recipe_stem
  echo ${RECIPE_TO_SOURCE_HASHMAP[$recipe_stem]}
  # if [ ${RECIPE_TO_SOURCE_HASHMAP[$recipe_stem]+_} ]; then output_name=${RECIPE_TO_SOURCE_HASHMAP[$recipe_stem]}; else output_name=$recipe_stem; fi
  if [ "${RECIPE_TO_SOURCE_HASHMAP[$recipe_stem]+abc}" ]; then # Return 'abc' if key exists. https://stackoverflow.com/questions/13219634/easiest-way-to-check-for-an-index-or-a-key-in-an-array
    output_name=${RECIPE_TO_SOURCE_HASHMAP[$recipe_stem]}
  else
    output_name=$recipe_stem
  fi
  echo "Fetching news from $output_name..."
  output_name="$output_name-$timestamp.epub"
  echo "File output name will be $output_name"
  # ebook-convert $recipe $output_name
  sleep 3
  # echo "Adding $recipe to
  echo
done
