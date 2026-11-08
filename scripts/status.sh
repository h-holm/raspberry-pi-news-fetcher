#!/usr/bin/env bash
# Prints a quick health overview: the last fetch, failed sources, and per reader the
# newest delivered issue, the sentinel and the last sync result.
#
# Usage: status.sh

PROGRAM_NAME="status.sh"
# shellcheck source=lib/common.sh
source "$(dirname "$(realpath "$0")")/lib/common.sh"
shopt -s nullglob

READERS_DIR="${READERS_DIR:-$REPO_DIR/config/readers}"
FETCHED_DIR="$REPO_DIR/fetched-news"

newest() { # newest fetched EPUB in dir $1, as "YYYY-MM-DD HH:MM name"
  find "$1" -maxdepth 1 -type f -name "*$FETCHED_EPUB_SUFFIX_GLOB" -printf '%TY-%Tm-%Td %TH:%TM %f\n' 2>/dev/null |
    sort | tail -n 1
}

echo "== Fetch ($FETCHED_DIR)"
echo "Newest EPUB:    $(newest "$FETCHED_DIR")"
if [[ -s $LOG_DIR/last_fetch_failures.txt ]]; then
  echo "Failed sources in the last run:"
  sed 's/^/  - /' "$LOG_DIR/last_fetch_failures.txt"
else
  echo "Failed sources in the last run: none"
fi

for conf in "$READERS_DIR"/*.conf; do
  name=$(basename "$conf" .conf)
  TARGET_DIR=""
  # shellcheck source=/dev/null
  source "$conf"
  echo
  echo "== Reader '$name' ($TARGET_DIR)"
  echo "Newest EPUB:    $(newest "$TARGET_DIR")"
  [[ -e $TARGET_DIR/$SENTINEL_NAME ]] && echo "Sentinel:       present" || echo "Sentinel:       MISSING"
  log_file="$LOG_DIR/reader-$name.out"
  if [[ -f $log_file ]]; then
    echo "Last sync OK:   $(grep 'Bisync OK' "$log_file" | tail -n 1 | cut -c1-19)"
    echo "Last problem:   $(grep -E 'ERROR|WARNING' "$log_file" | tail -n 1 | cut -c1-150)"
  else
    echo "Log:            '$log_file' not found"
  fi
done
