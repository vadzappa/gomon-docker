#!/bin/sh

IS_DEBUG='true'
if [ -n "${GO_NO_DEBUG}" ]; then
  IS_DEBUG='false'
fi

doRun() {
  echo "Running..."
  if [ "${IS_DEBUG}" = "true" ]; then
    dlv debug --wd /app --listen=:40000 --output=/tmp/debug_bin --headless=true --api-version=2 --log &
  else
    (cd /app && go build -race -o /tmp/run_bin)
    (cd /app && /tmp/run_bin &)
  fi
}

shutDown() {
  echo "Shutting down"

  if [ "${IS_DEBUG}" = "true" ]; then
    while [ -n "$(pidof dlv)" ] || [ -n "$(pidof debug_bin)" ]; do
      kill -9 "$(pidof dlv)" >/dev/null 2>&1
      kill -9 "$(pidof debug_bin)" >/dev/null 2>&1
    done
  else
    while [ -n "$(pidof run_bin)" ]; do
      kill -9 "$(pidof run_bin)" >/dev/null 2>&1
    done
  fi
}

trap "shutDown" INT TERM

doRun

rerunServer() {
  shutDown
  doRun
}

lockBuild() {
  if [ -f /tmp/server.lock ]; then
    inotifywait -e DELETE /tmp/server.lock
  fi
  touch /tmp/server.lock
}

unlockBuild() {
  rm -f /tmp/server.lock
}

inotifywait -e MODIFY -e DELETE -q -r -m /app 2>/dev/null |
  while read -r path action file; do
    ext="${file##*.}"
    if [ "${ext}" != "go" ]; then
      continue
    fi
    lockBuild
    echo "${action}-ed ${file}"
    rerunServer
    unlockBuild
  done
