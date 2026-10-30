#!/bin/bash
# Read-only row counts of the dev app's database on the phone, for checking an
# update didn't change data: run with "before", install, then "after" and diff.
# Copies the database to /tmp/myfin-db/<name>.sqlite; never writes to the phone.
set -euo pipefail
name=${1:?usage: tool/dev_db_count.sh before|after}
dir=/tmp/myfin-db
mkdir -p "$dir"
pkg=com.myfin.my_fin_tracker.dev
adb exec-out run-as $pkg cat app_flutter/my_fin_tracker.sqlite > "$dir/$name.sqlite"
adb exec-out run-as $pkg cat app_flutter/my_fin_tracker.sqlite-wal > "$dir/$name.sqlite-wal" 2>/dev/null || true
{
  for t in $(sqlite3 "$dir/$name.sqlite" "select name from sqlite_master where type='table' and name not like 'sqlite_%' order by name"); do
    echo "$t $(sqlite3 "$dir/$name.sqlite" "select count(*) from $t")"
  done
  echo "user_version $(sqlite3 "$dir/$name.sqlite" 'pragma user_version')"
  echo "liquid_sum $(sqlite3 "$dir/$name.sqlite" "select sum(p.amount) from postings p join accounts a on a.id=p.account_id where a.type in ('bank','cash','wallet')")"
} | tee "$dir/$name.txt"
grep -q '^entries ' "$dir/$name.txt" || { echo "No data read: is the phone connected and unlocked?" >&2; exit 1; }
