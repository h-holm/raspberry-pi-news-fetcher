#!/usr/bin/env bash
# Downloads the latest version of a Calibre recipe from upstream into recipes/.
#
# Usage: update_recipe.sh NAME [UPSTREAM_FILE]
#   NAME           Source name as written in the sources files, e.g. "Fokus". It is
#                  saved as recipes/NAME.recipe, which overrides Calibre's built-in one.
#   UPSTREAM_FILE  File name in calibre's repo (github.com/kovidgoyal/calibre,
#                  recipes/). Default: lowercased NAME + ".recipe". E.g. NZZ uses
#                  "nzz_ger.recipe".
#
# Afterwards, review the change with `git diff recipes/`, try it with
# scripts/test_recipe.sh NAME, and commit it. git history replaces the old dated
# backup copies.

PROGRAM_NAME="update_recipe.sh"
# shellcheck source=lib/common.sh
source "$(dirname "$(realpath "$0")")/lib/common.sh"

(($# >= 1 && $# <= 2)) || die "Usage: $PROGRAM_NAME NAME [UPSTREAM_FILE]"
NAME=$1
UPSTREAM_FILE=${2:-${NAME,,}.recipe}
URL="https://raw.githubusercontent.com/kovidgoyal/calibre/master/recipes/$UPSTREAM_FILE"
DEST="$REPO_DIR/recipes/$NAME.recipe"

require_cmd curl
tmp=$(mktemp)
trap 'rm -f -- "$tmp"' EXIT
log "Downloading '$URL'..."
curl -fsSL -m 60 -o "$tmp" "$URL" || die "Download failed. Check the upstream file name: https://github.com/kovidgoyal/calibre/tree/master/recipes"
grep -q 'BasicNewsRecipe' "$tmp" || die "'$URL' does not look like a Calibre recipe."

if [[ -f $DEST ]] && cmp -s "$tmp" "$DEST"; then
  log "'$DEST' is already up to date."
  exit 0
fi
mv -f -- "$tmp" "$DEST"
chmod 644 "$DEST"
log "Updated '$DEST'. Next: git diff recipes/ && scripts/test_recipe.sh '$NAME' && git commit."
