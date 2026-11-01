#!/bin/zsh
# Runs the in-app self-test against a fresh store in /tmp. Exit code 0 when every check passed.
# tools/selftest.sh basics,search runs only those check groups; a wrong name lists them.
set -u
rm -rf ~/Library/Saved\ Application\ State/__BUNDLE_ID__.savedState
store=/tmp/__APP_NAME__-self.store
rm -f $store $store-shm $store-wal
# A hang ends as a failure after 300 s instead of a stuck session.
# Plain zsh: macOS has no `timeout` unless Homebrew coreutils is installed.
APP_STORE=$store APP_SELFTEST_ONLY="${1:-}" ~/Applications/__APP_NAME__.app/Contents/MacOS/__APP_NAME__ --selftest &
app=$!
( sleep 300 && kill -KILL $app ) 2>/dev/null &
watchdog=$!
wait $app
code=$?
pkill -P $watchdog sleep 2>/dev/null
kill $watchdog 2>/dev/null
(( code == 137 )) && print "SELFTEST HUNG: killed after 300 s"
exit $code
