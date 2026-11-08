#!/usr/bin/env bash
# Delivers news to one reader: runs housekeep_news.sh, then run_rclone_bisync.sh,
# with the settings from config/readers/<name>.conf (see the .example file there).
#
# Usage: run_reader.sh NAME [--dry-run] [-v]
# The sync runs even if housekeeping failed. The exit status is non-zero if either
# step failed.

PROGRAM_NAME="run_reader.sh"
# shellcheck source=lib/common.sh
source "$(dirname "$(realpath "$0")")/lib/common.sh"

READERS_DIR="${READERS_DIR:-$REPO_DIR/config/readers}"

usage() {
  echo "Usage: $PROGRAM_NAME NAME [--dry-run] [-v]"
  echo "Readers configured in '$READERS_DIR':"
  local f
  for f in "$READERS_DIR"/*.conf; do [[ -e $f ]] && echo "  $(basename "$f" .conf)"; done
}

(($# >= 1)) || {
  usage >&2
  exit 2
}
[[ $1 == -h || $1 == --help ]] && {
  usage
  exit 0
}
NAME=$1
shift
DRY_RUN_FLAG=()
VERBOSE_FLAG=()
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN_FLAG=(--dry-run) ;;
    -v | --verbose) VERBOSE_FLAG=(-v) ;;
    *) usage >&2; exit 2 ;;
  esac
done

CONF="$READERS_DIR/$NAME.conf"
[[ -f $CONF ]] || die "No reader config '$CONF'."

SOURCES_FILE=""
TARGET_DIR=""
RCLONE_REMOTE=""
REMOTE_DIR=""
MAX_NUM_DAYS=6
FROM_DIR="$REPO_DIR/fetched-news"
# shellcheck source=/dev/null
source "$CONF"
# A relative SOURCES_FILE is relative to the readers config dir.
[[ $SOURCES_FILE == /* ]] || SOURCES_FILE="$READERS_DIR/$SOURCES_FILE"

for var in SOURCES_FILE TARGET_DIR RCLONE_REMOTE REMOTE_DIR; do
  [[ -n ${!var} ]] || die "$var is not set in '$CONF'."
done

rc=0
if ((${#DRY_RUN_FLAG[@]})); then
  log "Dry run: skipping housekeeping for reader '$NAME' (it has no dry-run mode)."
else
  "$SCRIPTS_DIR/housekeep_news.sh" "${VERBOSE_FLAG[@]}" \
    --sources-file "$SOURCES_FILE" --from-dir "$FROM_DIR" \
    --target-dir "$TARGET_DIR" --max-num-days "$MAX_NUM_DAYS" || rc=1
fi
"$SCRIPTS_DIR/run_rclone_bisync.sh" "${VERBOSE_FLAG[@]}" "${DRY_RUN_FLAG[@]}" \
  --local-dropbox-dir "$TARGET_DIR" --remote-name "$RCLONE_REMOTE" \
  --remote-dropbox-dir "$REMOTE_DIR" || rc=1
exit "$rc"
