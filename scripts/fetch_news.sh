#!/usr/bin/env bash
# Fetches news with Calibre's `ebook-convert` for every source listed in
# `--sources-file` and writes "<Source>-YYYY-MM-DD-HHMM.epub" files to `--output-dir`.
#
# A failing source never stops the others: the remaining sources are still fetched
# and delivered. Exit status: 0 if at least one source succeeded, 1 if every source
# failed, 2 on usage or setup errors.

PROGRAM_NAME="fetch_news.sh"
# shellcheck source=lib/common.sh
source "$(dirname "$(realpath "$0")")/lib/common.sh"

RECIPES_DIR="$REPO_DIR/recipes"
TIMEOUT="10m"
: "${PAUSE_SECONDS:=3}"
SOURCES_FILE=""
OUTPUT_DIR=""

usage() {
  cat <<EOF
Fetches news from the sources listed line by line in --sources-file using Calibre's
\`ebook-convert\` and saves the EPUBs to --output-dir. A failing source does not stop
the other sources from being fetched.

Usage: $PROGRAM_NAME -s SOURCES_FILE -o OUTPUT_DIR [-r RECIPES_DIR] [-t TIMEOUT] [-v]
  -s | --sources-file   Line-by-line list of news sources (blank lines and lines
                        starting with '#' are ignored).
  -o | --output-dir     Directory to write the EPUBs to (created if missing).
  -r | --recipes-dir    Directory of local \`.recipe\` files. A local
                        "<Source>.recipe" takes precedence over Calibre's built-in
                        recipe of the same name. Default: '$RECIPES_DIR'.
  -t | --timeout        Max time per source, as accepted by \`timeout\`. Default: $TIMEOUT.
  -v | --verbose        Keep and print ebook-convert's full output for every source.
  -h | --help           Show this help.

Exit status: 0 if at least one source succeeded, 1 if all failed, 2 on usage errors.
EOF
}

(($# > 0)) || {
  usage
  exit 2
}
OPTS=$(getopt -o s:o:r:t:vh -l sources-file:,output-dir:,recipes-dir:,timeout:,verbose,help \
  -n "$PROGRAM_NAME" -- "$@") || {
  usage >&2
  exit 2
}
eval set -- "$OPTS"
while true; do
  case "$1" in
    -s | --sources-file) SOURCES_FILE=$2; shift 2 ;;
    -o | --output-dir) OUTPUT_DIR=$(strip_trailing_slashes "$2"); shift 2 ;;
    -r | --recipes-dir) RECIPES_DIR=$(strip_trailing_slashes "$2"); shift 2 ;;
    -t | --timeout) TIMEOUT=$2; shift 2 ;;
    -v | --verbose) VERBOSE=1; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
  esac
done

require_cmd ebook-convert timeout mktemp
SOURCES=()
read_sources "$SOURCES_FILE" SOURCES
[[ -n $OUTPUT_DIR ]] || die "--output-dir is required."
require_dir --recipes-dir "$RECIPES_DIR"
mkdir -p "$OUTPUT_DIR/.partial" "$LOG_DIR/fetch"

acquire_lock "fetch-$(lock_key "$OUTPUT_DIR")"

log "Starting. Sources (${#SOURCES[@]}): $(printf "'%s' " "${SOURCES[@]}")"
log "Output dir: '$OUTPUT_DIR'. Local recipes dir: '$RECIPES_DIR'. Timeout per source: $TIMEOUT."

# Built-in recipe titles, one per line with surrounding whitespace removed.
BUILTIN_RECIPES=$(ebook-convert --list-recipes 2>&1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//') ||
  die "\`ebook-convert --list-recipes\` failed."

# In-progress downloads get neutral names (no source name) so that nothing matching
# "*<Source>*" (housekeep_news.sh, news-emailer) ever picks up a partial file.
# Leftovers from a crashed run are removed here.
find "$OUTPUT_DIR/.partial" -type f -mmin +720 -delete

timestamp=$(date +%Y-%m-%d-%H%M)
succeeded=()
failed=()

for src in "${SOURCES[@]}"; do
  if [[ -f "$RECIPES_DIR/$src.recipe" ]]; then
    recipe="$RECIPES_DIR/$src.recipe"
    kind="local"
  elif grep -Fxq -- "$src" <<<"$BUILTIN_RECIPES"; then
    recipe="$src.recipe"
    kind="built-in"
  else
    warn "No recipe for '$src': neither '$RECIPES_DIR/$src.recipe' nor a Calibre built-in. Skipping."
    failed+=("$src (no recipe found)")
    continue
  fi

  name="$src-$timestamp.epub"
  run_log="$LOG_DIR/fetch/$timestamp-$src.log"
  # Only reserve a unique name (-u): ebook-convert creates the file itself, so it gets
  # normal umask permissions instead of mktemp's private 0600.
  partial=$(mktemp -u --tmpdir="$OUTPUT_DIR/.partial" --suffix=.epub fetch.XXXXXX)
  log "Fetching '$src' with $kind recipe '$recipe'..."
  start=$SECONDS

  if timeout "$TIMEOUT" ebook-convert "$recipe" "$partial" >"$run_log" 2>&1; then
    mv -f -- "$partial" "$OUTPUT_DIR/$name"
    log "OK: '$src' -> '$name' ($((SECONDS - start))s)."
    succeeded+=("$src")
    if ((VERBOSE)); then cat "$run_log"; else rm -f -- "$run_log"; fi
  else
    rc=$?
    rm -f -- "$partial"
    ((rc == 124)) && reason="timed out after $TIMEOUT" || reason="exit code $rc"
    warn "FAILED: '$src' ($reason, $((SECONDS - start))s). Full output: '$run_log'. Last lines:"
    tail -n 15 "$run_log" | sed 's/^/    /' >&2
    failed+=("$src ($reason)")
  fi
  sleep "$PAUSE_SECONDS"
done

# Keep per-source logs of failed runs for 8 weeks.
find "$LOG_DIR/fetch" -type f -name '*.log' -mtime +56 -delete

failures_file="$LOG_DIR/last_fetch_failures.txt"
if ((${#failed[@]} > 0)); then
  printf '%s\n' "${failed[@]}" >"$failures_file"
  summary=$(printf -- '- %s\n' "${failed[@]}")
  warn "${#failed[@]} of ${#SOURCES[@]} sources failed:"$'\n'"$summary"
  notify "News fetch: ${#failed[@]} of ${#SOURCES[@]} sources failed" \
    "Fetch run $timestamp on $(hostname). Failed sources:"$'\n'"$summary"$'\n\n'"Logs: $LOG_DIR/fetch/"
else
  : >"$failures_file"
fi

log "Done: ${#succeeded[@]} succeeded, ${#failed[@]} failed."
((${#succeeded[@]} > 0)) || exit 1
