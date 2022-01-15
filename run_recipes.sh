#!/bin/bash

RECIPES_FOLDER="./recipes"
RECIPES="$RECIPES_FOLDER/*.recipe"

declare -A RECIPE_TO_SOURCE_HASHMAP
RECIPE_TO_SOURCE_HASHMAP["economist.recipe"]="The Economist"


for recipe in $RECIPES
do
  echo "Fetching news from $recipe"
  ebook-convert $recipe .epub
  sleep 3
  echo "Adding $recipe to 
done
