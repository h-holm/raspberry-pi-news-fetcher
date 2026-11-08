#!/usr/bin/env bash
# Bidirectionally syncs a reader's local Dropbox folder with its Dropbox remote
# using `rclone bisync`, hardened against the failure modes seen in practice:
#
# - A sentinel file (RCLONE_TEST) on both sides plus `--check-access` means neither
#   side is ever "empty", which used to abort bisync and force a manual --resync
#   (e.g. after housekeeping deleted last week's issues before the new fetch). A
#   missing sentinel is only recreated on a side that still has other files. If one
#   side is completely empty, that looks like a wipe: the run aborts and alerts
#   instead of mirroring the deletion.
# - `--resilient --recover` let later runs retry after transient errors.
# - If bisync still demands a resync, one automatic `--resync-mode newer` run is
#   made. A resync only ever copies; it never deletes.
#
# Requires `rclone` (>= 1.66) with the remote already configured.

PROGRAM_NAME="run_rclone_bisync.sh"
# shellcheck source=lib/common.sh
source "$(dirname "$(realpath "$0")")/lib/common.sh"

LOCAL_DIR=""
REMOTE_DIR=""
REMOTE_NAME=""
DRY_RUN=0
INIT=0

usage() {
  cat <<EOF
Bidirectionally syncs a local folder with a folder on an rclone remote.

Usage: $PROGRAM_NAME -l LOCAL_DIR -n REMOTE_NAME -r REMOTE_DIR [--init] [--dry-run] [-v]
  -l | --local-dropbox-dir   Local folder (e.g. ~/dropbox-news).
  -n | --remote-name         Name of the configured rclone remote.
  -r | --remote-dropbox-dir  Folder on that remote (e.g. "Apps/Rakuten Kobo").
       --init                First-time setup: create the $SENTINEL_NAME sentinel on
                             both sides (even if a side is empty) and run the initial
                             --resync-mode newer (which copies, never deletes).
       --dry-run             Show what would change; change nothing.
  -v | --verbose             Verbose rclone output.
  -h | --help                Show this help.
EOF
}

(($# > 0)) || {
  usage
  exit 2
}
OPTS=$(getopt -o l:r:n:vh -l local-dropbox-dir:,remote-dropbox-dir:,remote-name:,init,dry-run,verbose,help \
  -n "$PROGRAM_NAME" -- "$@") || {
  usage >&2
  exit 2
}
eval set -- "$OPTS"
while true; do
  case "$1" in
    -l | --local-dropbox-dir) LOCAL_DIR=$(strip_trailing_slashes "$2"); shift 2 ;;
    -r | --remote-dropbox-dir) REMOTE_DIR=$2; shift 2 ;;
    -n | --remote-name) REMOTE_NAME=$2; shift 2 ;;
    --init) INIT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -v | --verbose) VERBOSE=1; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
  esac
done

require_cmd rclone flock
require_dir --local-dropbox-dir "$LOCAL_DIR"
[[ -n $REMOTE_NAME ]] || die "--remote-name is required."
[[ -n $REMOTE_DIR ]] || die "--remote-dropbox-dir is required."
REMOTE_DIR=$(strip_trailing_slashes "${REMOTE_DIR#/}")
REMOTE="$REMOTE_NAME:/$REMOTE_DIR"

acquire_lock "bisync-$(lock_key "$LOCAL_DIR")"

alert() {
  warn "$1"
  notify "Dropbox sync problem: $LOCAL_DIR" "$1"$'\n\n'"Remote: $REMOTE. Host: $(hostname)."
}

# Make sure the sentinel exists on both sides (see the header comment).
ensure_sentinels() {
  local remote_files
  remote_files=$(rclone lsf --max-depth 1 -- "$REMOTE") || {
    alert "Could not list remote '$REMOTE' (offline or auth problem?)."
    exit 1
  }

  if [[ ! -e "$LOCAL_DIR/$SENTINEL_NAME" ]]; then
    if ((INIT)) || [[ -n $(find "$LOCAL_DIR" -mindepth 1 ! -name "$SENTINEL_NAME" -print -quit) ]]; then
      log "Creating missing sentinel '$LOCAL_DIR/$SENTINEL_NAME'."
      ((DRY_RUN)) || touch -- "$LOCAL_DIR/$SENTINEL_NAME"
    else
      alert "Local dir '$LOCAL_DIR' is completely empty (not even $SENTINEL_NAME). Refusing to sync, because that would delete everything on the remote. Restore the files, or run with --init if this is intended."
      exit 1
    fi
  fi

  if ! grep -Fxq -- "$SENTINEL_NAME" <<<"$remote_files"; then
    if ((INIT)) || grep -Fxv -- "$SENTINEL_NAME" <<<"$remote_files" | grep -q .; then
      log "Creating missing sentinel '$REMOTE/$SENTINEL_NAME'."
      ((DRY_RUN)) || rclone touch -- "$REMOTE/$SENTINEL_NAME"
    else
      alert "Remote '$REMOTE' is completely empty (not even $SENTINEL_NAME). Refusing to sync, because that would delete everything locally. Check the remote, or run with --init if this is intended."
      exit 1
    fi
  fi
}

BISYNC_ARGS=(
  bisync "$LOCAL_DIR" "$REMOTE"
  --check-access --check-filename "$SENTINEL_NAME"
  --resilient --recover --max-lock 15m
  --conflict-resolve newer
  # Weekly rotation routinely deletes >50% of a small folder, so bypass the
  # percentage check; wipe protection comes from the sentinel checks above.
  --force
  --color NEVER
)
((VERBOSE)) && BISYNC_ARGS+=(-v)
((DRY_RUN)) && BISYNC_ARGS+=(--dry-run)
((INIT)) && BISYNC_ARGS+=(--resync-mode newer)

ensure_sentinels

out=$(mktemp)
trap 'rm -f -- "$out"' EXIT

debug "Running: rclone ${BISYNC_ARGS[*]}"
if rclone "${BISYNC_ARGS[@]}" >"$out" 2>&1; then
  cat "$out"
  log "Bisync OK: '$LOCAL_DIR' <-> '$REMOTE'."
  exit 0
fi

cat "$out"
# Match rclone's exact wording: with --resilient it also prints "retryable without
# --resync", which must not trigger a resync.
if ! grep -q -- "Must run --resync" "$out"; then
  alert "rclone bisync failed (see log). It does not ask for a resync, so the next run will retry."
  exit 1
fi

warn "rclone bisync requires a resync; attempting one automatic '--resync-mode newer' run."
if rclone "${BISYNC_ARGS[@]}" --resync-mode newer >"$out" 2>&1; then
  cat "$out"
  alert "Bisync needed a resync and it succeeded automatically. Files deleted on only one side since the last good sync may have been restored."
  exit 0
fi
cat "$out"
alert "Bisync failed, and the automatic resync failed too. Manual action needed: rclone bisync --resync-mode newer -v '$LOCAL_DIR' '$REMOTE'."
exit 1
