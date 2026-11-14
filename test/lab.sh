#!/usr/bin/env bash
# What compose.yaml's header promises, checked through docker exec, which is how the platform's
# terminal reaches the lab: run by check.sh. Every Run prints the same each time, so lines are
# held exactly, and the order matters: a crash, then the resume that follows it.
set -euo pipefail
: "${WORKER:?run through test/check.sh}"
: "${DB:?run through test/check.sh}"
worker() { docker exec "$WORKER" "$@"; }
sql() { docker exec "$DB" psql -U durable -At -c "$1"; }
expect() { # expect "<command output>" <line that must be in it>...
  local out="$1"; shift
  for want in "$@"; do
    echo "$out" | grep -Fxq -- "$want" || { echo "missing '$want' in: $out" >&2; exit 1; }
  done
}
crashes() { # crashes <args...>: the Run must stop with exit code 3 and say so
  local out code=0
  out=$(worker python3 "$@") || code=$?
  [ "$code" = 3 ] || { echo "expected exit code 3 from $*, got $code: $out" >&2; exit 1; }
  echo "$out" | grep -q '^\*\*\* crash on purpose' || { echo "no crash line from $*" >&2; exit 1; }
  echo "$out"
}

echo "- the worker wrote its files and runs as an unprivileged account"
worker ls pg.py engine.py shop.py naive.py order.py retry.py remind.py saga.py >/dev/null
[ "$(worker id -u)" = 65532 ] || { echo "the worker is not 65532" >&2; exit 1; }

echo "- a plain job retried from the top charges twice"
crashes naive.py order-1 --fresh --crash-after charge_card >/dev/null
worker python3 naive.py order-1 >/dev/null
[ "$(sql "SELECT count(*) FROM payments WHERE workflow = 'order-1'")" = 2 ] || { echo "order-1 should have 2 payments" >&2; exit 1; }

echo "- a durable workflow resumes from its journal and charges once"
crashes order.py order-7 --fresh --crash-after 2 >/dev/null
[ "$(sql "SELECT string_agg(step, ',' ORDER BY seq) FROM journal WHERE workflow = 'order-7'")" = "reserve_stock,charge_card" ] \
  || { echo "order-7's journal is wrong" >&2; exit 1; }
expect "$(worker python3 order.py order-7)" \
  'workflow order-7, journal rows found: 2' \
  '  replay  #1 charge_card -> {"charged": 2500}' \
  '  run     #3 book_courier -> {"tracking": "TRK-order-7"}'
[ "$(sql "SELECT count(*) FROM payments WHERE workflow = 'order-7'")" = 1 ] || { echo "order-7 should have 1 payment" >&2; exit 1; }

echo "- a crash inside the charge repeats it, unless it carries a key"
crashes order.py order-8 --fresh --crash-inside charge_card >/dev/null
worker python3 order.py order-8 >/dev/null
[ "$(sql "SELECT count(*) FROM payments WHERE workflow = 'order-8'")" = 2 ] || { echo "order-8 should have 2 payments" >&2; exit 1; }
crashes order.py order-9 --fresh --keyed --crash-inside charge_card >/dev/null
expect "$(worker python3 order.py order-9 --keyed)" \
  '  run     #1 charge_card -> {"charged": 2500, "key": "order-9:charge_card", "repeat": true}'
[ "$(sql "SELECT count(*) FROM payments WHERE workflow = 'order-9'")" = 1 ] || { echo "order-9 should have 1 payment" >&2; exit 1; }

echo "- backoff, jitter from a fixed seed, and a durable timer on a given clock"
expect "$(worker python3 retry.py --fail 3)" 'attempt 3 timed out after 2.0 s, wait 2.0 s' 'attempt 4 charged' 'waited 3.5 s in all'
expect "$(worker python3 retry.py --fail 9 --attempts 6 --jitter)" 'waited 4.04 s in all'
worker python3 remind.py inv-1 --fresh --now 0 >/dev/null
expect "$(worker python3 remind.py inv-1 --now 86400)" 'now 86400: the timer is not due, 172800 s left; nothing runs while it waits'
expect "$(worker python3 remind.py inv-1 --now 260000)" '  run     #2 send_reminder -> {"emailed": "reminder"}'

echo "- a saga compensates newest first, and survives a crash in the undo"
expect "$(worker python3 saga.py trip-2 --fresh --fail-at book_car)" \
  '  run     #3 cancel_hotel -> {"cancelled": "hotel"}' '  run     #4 cancel_flight -> {"cancelled": "flight"}'
[ "$(sql "SELECT string_agg(item || '=' || status, ',' ORDER BY id) FROM bookings WHERE workflow = 'trip-2'")" = "flight=cancelled,hotel=cancelled" ] \
  || { echo "trip-2 should be cancelled" >&2; exit 1; }
crashes saga.py trip-3 --fresh --fail-at book_car --crash-after 3 >/dev/null
expect "$(worker python3 saga.py trip-3 --fail-at book_car)" 'saga trip-3 undone: nothing is left booked'

echo "- changed workflow code is caught as not deterministic"
crashes order.py order-10 --fresh --crash-after 2 >/dev/null
code=0; out=$(worker python3 order.py order-10 --v2) || code=$?
[ "$code" = 1 ] || { echo "the v2 resume should exit 1" >&2; exit 1; }
expect "$out" 'stopped, not deterministic: step 1: the journal has charge_card but the code now asks for send_receipt'

echo "- no way out to the internet"
if worker python3 -c "import socket; socket.create_connection(('example.com', 443), timeout=4)" 2>/dev/null; then
  echo "the lab reached the internet" >&2; exit 1
fi
