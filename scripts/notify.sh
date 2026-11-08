#!/usr/bin/env bash
# Sends an alert: notify.sh SUBJECT BODY
#
# Configured by config/notify.conf (gitignored; see config/notify.conf.example).
# Without that file this script does nothing, so alerting is opt-in. Supports email
# via mutt (using the existing ~/.muttrc) and/or an ntfy.sh topic URL via curl. The
# same subject is sent at most once per NOTIFY_MIN_INTERVAL_HOURS, so a sync failing
# every 30 minutes doesn't flood the inbox.

PROGRAM_NAME="notify.sh"
# shellcheck source=lib/common.sh
source "$(dirname "$(realpath "$0")")/lib/common.sh"

(($# == 2)) || die "Usage: $PROGRAM_NAME SUBJECT BODY"
SUBJECT=$1
BODY=$2

CONF="${NOTIFY_CONF:-$REPO_DIR/config/notify.conf}"
[[ -f $CONF ]] || exit 0

NOTIFY_EMAIL=""
NOTIFY_NTFY_URL=""
NOTIFY_MIN_INTERVAL_HOURS=12
# shellcheck source=/dev/null
source "$CONF"

mkdir -p "$STATE_DIR/notify"
stamp="$STATE_DIR/notify/$(printf '%s' "$SUBJECT" | md5sum | cut -c1-16)"
if [[ -n $(find "$stamp" -mmin -$((NOTIFY_MIN_INTERVAL_HOURS * 60)) 2>/dev/null) ]]; then
  log "Not re-sending '$SUBJECT' (already sent within ${NOTIFY_MIN_INTERVAL_HOURS}h)."
  exit 0
fi

sent=0
if [[ -n $NOTIFY_EMAIL ]]; then
  require_cmd mutt
  if printf '%s\n' "$BODY" | mutt -s "[news-fetcher] $SUBJECT" -- "$NOTIFY_EMAIL"; then
    sent=1
  else
    warn "mutt failed to send '$SUBJECT'."
  fi
fi
if [[ -n $NOTIFY_NTFY_URL ]]; then
  require_cmd curl
  if curl -fsS -m 30 -H "Title: [news-fetcher] $SUBJECT" --data-binary "$BODY" "$NOTIFY_NTFY_URL" >/dev/null; then
    sent=1
  else
    warn "ntfy request failed for '$SUBJECT'."
  fi
fi

if ((sent)); then
  touch -- "$stamp"
  log "Sent notification '$SUBJECT'."
else
  exit 1
fi
