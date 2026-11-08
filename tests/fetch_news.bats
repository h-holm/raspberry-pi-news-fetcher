#!/usr/bin/env bats
load test_helper

fetch() {
  "$SCRIPTS/fetch_news.sh" --sources-file "$WORK/sources" --output-dir "$WORK/fetched/" \
    --recipes-dir "$WORK/recipes" "$@"
}

@test "a local recipe takes precedence over a built-in one" {
  printf 'Fokus\n' >"$WORK/sources"
  echo "local" >"$WORK/recipes/Fokus.recipe"
  export FAKE_BUILTIN_RECIPES="Fokus"
  run fetch
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_CALLS")" = "$WORK/recipes/Fokus.recipe" ]
  ls "$WORK/fetched"/Fokus-????-??-??-????.epub
}

@test "a built-in recipe is used when no local one exists" {
  printf 'The Economist\n' >"$WORK/sources"
  export FAKE_BUILTIN_RECIPES=$'NZZ\nThe Economist'
  run fetch
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_CALLS")" = "The Economist.recipe" ]
}

@test "partial failure: other sources are still fetched and the run exits 0" {
  printf 'Fail Source\nNZZ\nNo Such Source\nLe Monde\n' >"$WORK/sources"
  export FAKE_BUILTIN_RECIPES=$'NZZ\nLe Monde\nFail Source'
  run fetch
  [ "$status" -eq 0 ]
  ls "$WORK/fetched"/NZZ-*.epub "$WORK/fetched"/"Le Monde"-*.epub
  ! ls "$WORK/fetched"/Fail*
  [ -z "$(ls -A "$WORK/fetched/.partial")" ]
  grep -q "^Fail Source (exit code 1)$" "$LOG_DIR/last_fetch_failures.txt"
  grep -q "^No Such Source (no recipe found)$" "$LOG_DIR/last_fetch_failures.txt"
  [[ $output == *"HTTP Error 403"* ]]
}

@test "the run exits 1 when every source fails" {
  printf 'Fail One\nFail Two\n' >"$WORK/sources"
  export FAKE_BUILTIN_RECIPES=$'Fail One\nFail Two'
  run fetch
  [ "$status" -eq 1 ]
}

@test "the failures file is emptied after a fully successful run" {
  echo "old failure" >"$LOG_DIR/last_fetch_failures.txt"
  printf 'NZZ\n' >"$WORK/sources"
  export FAKE_BUILTIN_RECIPES="NZZ"
  run fetch
  [ "$status" -eq 0 ]
  [ ! -s "$LOG_DIR/last_fetch_failures.txt" ]
}

@test "source names are matched literally against built-ins, not as regexes" {
  printf 'FAZ.NET\n' >"$WORK/sources"
  export FAKE_BUILTIN_RECIPES="FAZxNET"
  run fetch
  [ "$status" -eq 1 ]
  [ ! -s "$FAKE_CALLS" ]
}

@test "a source exceeding --timeout fails without blocking the others" {
  printf 'Hang Source\nNZZ\n' >"$WORK/sources"
  export FAKE_BUILTIN_RECIPES=$'Hang Source\nNZZ'
  run fetch --timeout 1s
  [ "$status" -eq 0 ]
  grep -q "^Hang Source (timed out after 1s)$" "$LOG_DIR/last_fetch_failures.txt"
  ls "$WORK/fetched"/NZZ-*.epub
}

@test "EPUBs get normal umask permissions" {
  printf 'NZZ\n' >"$WORK/sources"
  export FAKE_BUILTIN_RECIPES="NZZ"
  umask 0002
  run fetch
  [ "$status" -eq 0 ]
  [ "$(stat -c %a "$WORK/fetched"/NZZ-*.epub)" = "664" ]
}

@test "usage errors exit 2" {
  run "$SCRIPTS/fetch_news.sh"
  [ "$status" -eq 2 ]
  run "$SCRIPTS/fetch_news.sh" --bogus
  [ "$status" -eq 2 ]
}
