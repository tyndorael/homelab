#!/bin/bash
# OrbStack watchdog — keeps Docker running on the Mac mini without anyone at the keyboard.
# After a reboot the OrbStack app is started at login (app.start_at_login) but its engine can stay
# "Stopped", which leaves every container down. Run by launchd at login and every 2 minutes:
#   1. Docker answers            -> nothing to do (silent)
#   2. otherwise `orb start`     -> wait up to 60 s
#   3. still down                -> quit and relaunch the OrbStack app (what fixed it by hand)
set -u
export PATH="$HOME/.orbstack/bin:/opt/homebrew/bin:/usr/bin:/bin"
LOG="$HOME/Library/Logs/homelab-orbstack-watchdog.log"
log(){ echo "$(date '+%F %T') $*" >> "$LOG"; }
limit(){ perl -e 'alarm shift; exec @ARGV' "$@"; }          # macOS has no `timeout`
docker_ok(){ limit 15 docker info >/dev/null 2>&1; }
wait_docker(){ for _ in $(seq 1 "$1"); do docker_ok && return 0; sleep 5; done; return 1; }

docker_ok && exit 0

# Give a fresh login a moment: OrbStack may simply still be booting.
if [ "$(sysctl -n kern.boottime | sed -E 's/.*sec = ([0-9]+).*/\1/')" -gt "$(( $(date +%s) - 180 ))" ]; then
  wait_docker 12 && exit 0
fi

log "Docker not responding -> orb start"
limit 60 orb start >/dev/null 2>&1
if wait_docker 12; then log "recovered with orb start"; exit 0; fi

log "still down -> relaunching OrbStack app"
limit 20 osascript -e 'quit app "OrbStack"' >/dev/null 2>&1
sleep 3; pkill -x OrbStack 2>/dev/null; sleep 2
open -g -a OrbStack
if wait_docker 24; then log "recovered by relaunching OrbStack"; else log "FAILED to recover Docker"; exit 1; fi
