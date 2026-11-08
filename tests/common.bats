#!/usr/bin/env bats
load test_helper

read_into() { # prints the parsed sources one per line, with brackets
  bash -c 'source "$1/lib/common.sh"; read_sources "$2" S; printf "[%s]\n" "${S[@]}"' _ "$SCRIPTS" "$1"
}

@test "read_sources trims whitespace and skips blank lines, comments and CRLF" {
  printf '# comment\n  The Economist  \n\nFokus\r\n\t\n自由電子報\nNo newline at end' >"$WORK/s"
  run read_into "$WORK/s"
  [ "$status" -eq 0 ]
  [ "$output" = $'[The Economist]\n[Fokus]\n[自由電子報]\n[No newline at end]' ]
}

@test "read_sources dies on a file without sources" {
  printf '# only a comment\n\n' >"$WORK/s"
  run read_into "$WORK/s"
  [ "$status" -eq 2 ]
  [[ $output == *"lists no sources"* ]]
}

@test "read_sources dies on a missing file" {
  run read_into "$WORK/missing"
  [ "$status" -eq 2 ]
}

@test "strip_trailing_slashes" {
  run bash -c 'source "$1/lib/common.sh"; strip_trailing_slashes /a/b//; echo; strip_trailing_slashes /' _ "$SCRIPTS"
  [ "$output" = $'/a/b\n/' ]
}
