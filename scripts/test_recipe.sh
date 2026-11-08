#!/usr/bin/env bash
# Quick check of one source's recipe: fetches only a couple of articles
# (`ebook-convert --test`) into a temp file and reports success or failure.
#
# Usage: test_recipe.sh NAME [-v]
# Uses recipes/NAME.recipe if it exists, otherwise Calibre's built-in recipe NAME.

PROGRAM_NAME="test_recipe.sh"
# shellcheck source=lib/common.sh
source "$(dirname "$(realpath "$0")")/lib/common.sh"

(($# >= 1)) || die "Usage: $PROGRAM_NAME NAME [-v]"
NAME=$1
[[ ${2:-} == -v ]] && VERBOSE=1

require_cmd ebook-convert
recipe="$REPO_DIR/recipes/$NAME.recipe"
[[ -f $recipe ]] || recipe="$NAME.recipe"

out_dir=$(mktemp -d)
trap 'rm -rf -- "$out_dir"' EXIT
args=("$recipe" "$out_dir/test.epub" --test)
((VERBOSE)) && args+=(-vv)

log "Testing recipe '$recipe'..."
if ebook-convert "${args[@]}"; then
  log "OK: produced $(du -h "$out_dir/test.epub" | cut -f1) EPUB from '$recipe'."
else
  die "Recipe '$recipe' failed."
fi
