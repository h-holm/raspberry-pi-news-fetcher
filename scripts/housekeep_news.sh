#!/usr/bin/env bash
# Delivers fetched news EPUBs to one reader's local Dropbox folder and cleans up:
#   1. deletes EPUBs older than --max-num-days from --from-dir (the fetcher's
#      output dir; every EPUB there is fetcher-owned, whatever its source),
#   2. deletes fetched EPUBs older than --max-num-days from --target-dir. Only files
#      named like the fetcher's output ("<Source>-YYYY-MM-DD-HHMM.epub") are ever
#      deleted there, because readers keep their own books in the same folder,
#   3. copies EPUBs of the sources in --sources-file from --from-dir to --target-dir,
#      once per file. A ledger in $STATE_DIR records what was delivered, so an issue
#      the reader deleted (e.g. from Dropbox) is not copied back again.

PROGRAM_NAME="housekeep_news.sh"
# shellcheck source=lib/common.sh
source "$(dirname "$(realpath "$0")")/lib/common.sh"

SOURCES_FILE=""
FROM_DIR=""
TARGET_DIR=""
MAX_NUM_DAYS=""

usage() {
  cat <<EOF
Delivers fetched news EPUBs to a reader's folder and deletes old ones.

Usage: $PROGRAM_NAME -s SOURCES_FILE -f FROM_DIR -t TARGET_DIR -m MAX_NUM_DAYS [-v]
  -s | --sources-file   Line-by-line list of the reader's news sources.
  -f | --from-dir       Directory the fetcher writes EPUBs to.
  -t | --target-dir     The reader's local (Dropbox-synced) directory.
  -m | --max-num-days   Delete fetched EPUBs older than this (as \`find -mtime +N\`).
  -v | --verbose        Also log when nothing changed.
  -h | --help           Show this help.

Only files named "<Source>-YYYY-MM-DD-HHMM.epub" are ever deleted from TARGET_DIR.
EOF
}

(($# > 0)) || {
  usage
  exit 2
}
OPTS=$(getopt -o s:f:t:m:vh -l sources-file:,from-dir:,target-dir:,max-num-days:,verbose,help \
  -n "$PROGRAM_NAME" -- "$@") || {
  usage >&2
  exit 2
}
eval set -- "$OPTS"
while true; do
  case "$1" in
    -s | --sources-file) SOURCES_FILE=$2; shift 2 ;;
    -f | --from-dir) FROM_DIR=$(strip_trailing_slashes "$2"); shift 2 ;;
    -t | --target-dir) TARGET_DIR=$(strip_trailing_slashes "$2"); shift 2 ;;
    -m | --max-num-days) MAX_NUM_DAYS=$2; shift 2 ;;
    -v | --verbose) VERBOSE=1; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
  esac
done

SOURCES=()
read_sources "$SOURCES_FILE" SOURCES
require_dir --from-dir "$FROM_DIR"
require_dir --target-dir "$TARGET_DIR"
[[ $MAX_NUM_DAYS =~ ^[1-9][0-9]*$ ]] ||
  die "--max-num-days must be an integer greater than 0, got '$MAX_NUM_DAYS'."

acquire_lock "housekeep-$(lock_key "$TARGET_DIR")"
shopt -s nullglob
mkdir -p "$STATE_DIR"
ledger="$STATE_DIR/delivered-$(lock_key "$TARGET_DIR").txt"

# First run with a ledger: everything already in the target counts as delivered.
if [[ ! -f $ledger ]]; then
  # shellcheck disable=SC2231 # the suffix is a glob on purpose
  for f in "$TARGET_DIR"/*$FETCHED_EPUB_SUFFIX_GLOB; do basename -- "$f"; done >"$ledger"
  log "Created delivery ledger '$ledger' ($(wc -l <"$ledger") entries)."
fi

changes=0

# 1 + 2. Delete old fetched EPUBs.
while IFS= read -r -d '' f; do
  log "Deleted old EPUB '$f'."
  changes=$((changes + 1))
done < <(
  find "$FROM_DIR" -maxdepth 1 -type f -name '*.epub' -mtime +"$MAX_NUM_DAYS" -print0 -delete
  find "$TARGET_DIR" -maxdepth 1 -type f -name "*$FETCHED_EPUB_SUFFIX_GLOB" \
    -mtime +"$MAX_NUM_DAYS" -print0 -delete
)

# 3. Copy new EPUBs of this reader's sources, once each.
copied=0
for src in "${SOURCES[@]}"; do
  for f in "$FROM_DIR/$src"$FETCHED_EPUB_SUFFIX_GLOB; do
    name=$(basename -- "$f")
    grep -Fxq -- "$name" "$ledger" && continue
    if [[ ! -e "$TARGET_DIR/$name" ]]; then
      cp -p -- "$f" "$TARGET_DIR/$name"
      log "Copied '$name' to '$TARGET_DIR'."
      copied=$((copied + 1))
    fi
    printf '%s\n' "$name" >>"$ledger"
  done
done
changes=$((changes + copied))

# Forget ledger entries whose file is gone from FROM_DIR (it can never be copied
# again), so the ledger stays small.
tmp=$(mktemp "$ledger.XXXXXX")
while IFS= read -r name; do
  [[ -e "$FROM_DIR/$name" ]] && printf '%s\n' "$name"
done <"$ledger" >"$tmp" || true
mv -f -- "$tmp" "$ledger"

if ((changes > 0 || VERBOSE)); then
  log "Done for '$TARGET_DIR': copied $copied, deleted $((changes - copied))."
fi
