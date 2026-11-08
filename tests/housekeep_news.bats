#!/usr/bin/env bats
load test_helper

housekeep() {
  "$SCRIPTS/housekeep_news.sh" --sources-file "$WORK/sources" --from-dir "$WORK/fetched" \
    --target-dir "$WORK/target/" --max-num-days 6 "$@"
}

@test "copies only the reader's sources, preserving mtime" {
  printf 'Fokus\n' >"$WORK/sources"
  epub "Fokus-2026-11-06-1500.epub" 1 "$WORK/fetched"
  epub "NZZ-2026-11-06-1500.epub" 1 "$WORK/fetched"
  epub "Fokus Extra-2026-11-06-1500.epub" 1 "$WORK/fetched"
  run housekeep
  [ "$status" -eq 0 ]
  [ "$(ls "$WORK/target")" = "Fokus-2026-11-06-1500.epub" ]
  [ "$(stat -c %Y "$WORK/target/Fokus-2026-11-06-1500.epub")" = "$(stat -c %Y "$WORK/fetched/Fokus-2026-11-06-1500.epub")" ]
}

@test "an issue the reader deleted is not copied back" {
  printf 'Fokus\n' >"$WORK/sources"
  epub "Fokus-2026-11-06-1500.epub" 1 "$WORK/fetched"
  run housekeep
  rm "$WORK/target/Fokus-2026-11-06-1500.epub"
  run housekeep
  [ "$status" -eq 0 ]
  [ -z "$(ls "$WORK/target")" ]
}

@test "deletes old fetched issues from the target but never the reader's own books" {
  printf 'Fokus\n' >"$WORK/sources"
  epub "Fokus-2026-10-23-1500.epub" 14 "$WORK/target"
  epub "Atlantic-2026-10-23-1500.epub" 14 "$WORK/target"   # source no longer listed
  epub "Fokus-2026-11-06-1500.epub" 1 "$WORK/target"
  epub "Niemi, Mikael - Fallvatten.epub" 400 "$WORK/target"
  epub "Fokus special edition.epub" 400 "$WORK/target"
  epub "notes.pdf" 400 "$WORK/target"
  touch "$WORK/target/RCLONE_TEST"
  touch -d "400 days ago" "$WORK/target/RCLONE_TEST"
  run housekeep
  [ "$status" -eq 0 ]
  run env LC_ALL=C ls "$WORK/target"
  [ "$output" = $'Fokus special edition.epub\nFokus-2026-11-06-1500.epub\nNiemi, Mikael - Fallvatten.epub\nRCLONE_TEST\nnotes.pdf' ]
}

@test "deletes old EPUBs of any source from the from-dir (orphans)" {
  printf 'Fokus\n' >"$WORK/sources"
  epub "南方周末-2025-11-14-1500.epub" 360 "$WORK/fetched"
  epub "Fokus-2026-11-06-1500.epub" 1 "$WORK/fetched"
  run housekeep
  [ "$status" -eq 0 ]
  [ "$(ls "$WORK/fetched")" = "Fokus-2026-11-06-1500.epub" ]
}

@test "is quiet when nothing changed" {
  printf 'Fokus\n' >"$WORK/sources"
  epub "Fokus-2026-11-06-1500.epub" 1 "$WORK/fetched"
  run housekeep
  [[ $output == *"Created delivery ledger"* ]]
  run housekeep
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "rejects an invalid --max-num-days" {
  printf 'Fokus\n' >"$WORK/sources"
  run "$SCRIPTS/housekeep_news.sh" -s "$WORK/sources" -f "$WORK/fetched" -t "$WORK/target" -m abc
  [ "$status" -eq 2 ]
  run "$SCRIPTS/housekeep_news.sh" -s "$WORK/sources" -f "$WORK/fetched" -t "$WORK/target" -m 0
  [ "$status" -eq 2 ]
}

@test "skips the run when another one holds the lock" {
  printf 'Fokus\n' >"$WORK/sources"
  epub "Fokus-2026-11-06-1500.epub" 1 "$WORK/fetched"
  key=$(bash -c 'source "$1/lib/common.sh"; lock_key "$2"' _ "$SCRIPTS" "$WORK/target")
  exec {fd}>"$LOCK_DIR/news-fetcher-housekeep-$key.lock"
  flock -n "$fd"
  run housekeep
  [ "$status" -eq 0 ]
  [[ $output == *"skipping this run"* ]]
  [ -z "$(ls "$WORK/target")" ]
}
