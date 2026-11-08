# Shared setup for the bats tests: an isolated temp workspace, fake binaries first
# on PATH, and state, log and lock dirs that never touch the real ones.
REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"

setup() {
  WORK="$BATS_TEST_TMPDIR/work"
  mkdir -p "$WORK"/{fetched,target,recipes,remote/kobo,local,logs,state,locks}
  export PATH="$REPO_ROOT/tests/fakes:$PATH"
  export LOG_DIR="$WORK/logs" STATE_DIR="$WORK/state" LOCK_DIR="$WORK/locks"
  export NOTIFY_CONF="$WORK/no-notify.conf" PAUSE_SECONDS=0
  export FAKE_CALLS="$WORK/calls.log" FAKE_REMOTE_ROOT="$WORK/remote"
  export FAKE_BUILTIN_RECIPES=""
  : >"$FAKE_CALLS"
}

# epub NAME [AGE_DAYS] DIR -> creates DIR/NAME with an mtime AGE_DAYS days ago.
epub() {
  echo "x" >"$3/$1"
  touch -d "${2:-0} days ago" "$3/$1"
}
