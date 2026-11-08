# shellcheck shell=bash
# Shared helpers for the news-fetcher scripts. Source this file; don't execute it.
#
# Requires bash >= 4.3 (namerefs) and GNU coreutils/util-linux (as on Raspberry Pi
# OS / Debian). Every function prints to stdout/stderr, which cron redirects into the
# per-script log files.

set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(dirname "$LIB_DIR")"
REPO_DIR="$(dirname "$SCRIPTS_DIR")"

: "${PROGRAM_NAME:=$(basename "$0")}"
: "${VERBOSE:=0}"
: "${LOG_DIR:=$REPO_DIR/logs}"
: "${STATE_DIR:=$REPO_DIR/state}"
: "${LOCK_DIR:=/tmp}"

# The constants below are used by the scripts that source this file.
# shellcheck disable=SC2034
# Name of the sentinel file `rclone bisync --check-access` looks for on both sides.
SENTINEL_NAME="RCLONE_TEST"

# shellcheck disable=SC2034
# Glob matching EPUBs produced by fetch_news.sh: "<Source>-YYYY-MM-DD-HHMM.epub".
FETCHED_EPUB_SUFFIX_GLOB='-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9].epub'

log() { printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$PROGRAM_NAME" "$*"; }
debug() { if ((VERBOSE)); then log "$@"; fi; }
warn() { log "WARNING: $*" >&2; }
die() {
  log "ERROR: $*" >&2
  exit 2
}

require_cmd() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command '$cmd' not found on PATH ($PATH)."
  done
}

# strip_trailing_slashes PATH -> prints PATH without trailing slashes ("/" stays "/").
strip_trailing_slashes() {
  local p=$1
  while [[ $p == */ && $p != / ]]; do p=${p%/}; done
  printf '%s' "$p"
}

# require_dir FLAG PATH -> dies unless PATH is an existing directory.
require_dir() {
  [[ -n $2 ]] || die "$1 is required."
  [[ -d $2 ]] || die "$1 '$2' is not an existing directory."
}

# read_sources FILE ARRAY_NAME
# Reads one news source per line into the named array. Leading/trailing whitespace
# (including Windows line endings) is trimmed; blank lines and lines starting with
# '#' are skipped. Dies if the file is missing or yields no sources.
read_sources() {
  local file=$1
  local -n _sources_out=$2
  [[ -n $file ]] || die "--sources-file is required."
  [[ -f $file ]] || die "Sources file '$file' does not exist."
  _sources_out=()
  local line
  while IFS= read -r line || [[ -n $line ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z $line || $line == \#* ]] && continue
    _sources_out+=("$line")
  done <"$file"
  ((${#_sources_out[@]} > 0)) || die "Sources file '$file' lists no sources."
}

# lock_key PATH -> a filesystem-safe key derived from PATH, for lock/state file names.
lock_key() {
  local p
  p=$(strip_trailing_slashes "$1")
  p=${p#/}
  printf '%s' "${p//[^A-Za-z0-9._-]/_}"
}

# acquire_lock NAME
# Takes an exclusive, non-blocking lock for the rest of the script's lifetime. If
# another run already holds it, logs that and exits 0, so overlapping cron runs
# are skipped quietly instead of racing each other.
acquire_lock() {
  local file="$LOCK_DIR/news-fetcher-$1.lock"
  exec {LOCK_FD}>"$file" || die "Cannot open lock file '$file'."
  if ! flock -n "$LOCK_FD"; then
    log "Another run holds lock '$file'; skipping this run."
    exit 0
  fi
}

# notify SUBJECT BODY
# Sends an alert via scripts/notify.sh. This is a no-op unless config/notify.conf
# exists, and a failure to notify never fails the calling script.
notify() {
  "$SCRIPTS_DIR/notify.sh" "$1" "$2" || warn "Sending notification failed."
}
