#!/bin/sh

IS_DEBUG='true'
if [ -n "${GO_NO_DEBUG}" ]; then
  IS_DEBUG='false'
fi

tail_pid=0
notifier_pid=0

lockBuild() {
  if [ -f /tmp/server.lock ]; then
    inotifywait -e DELETE /tmp/server.lock
  fi
  touch /tmp/server.lock
}

unlockBuild() {
  rm -f /tmp/server.lock
}

doRun() {
  echo "Starting up application..."
  if [ "${IS_DEBUG}" = "true" ]; then
    dlv debug --wd /app --listen=:40000 --output=/tmp/debug_bin --headless=true --api-version=2 --log &
  else
    (cd /app && go build -race -o /tmp/run_bin)
    (cd /app && /tmp/run_bin &)
  fi
}

stopApp() {
  if [ "${IS_DEBUG}" = "true" ]; then
    while [ -n "$(pidof dlv)" ] || [ -n "$(pidof debug_bin)" ]; do
      kill -9 "$(pidof dlv)" >/dev/null 2>&1
      kill -9 "$(pidof debug_bin)" >/dev/null 2>&1
    done
  else
    while [ -n "$(pidof run_bin)" ]; do
      kill -s TERM "$(pidof run_bin)" >/dev/null 2>&1
    done
  fi
}

shutDown() {
  echo "Shutting down"

  if [ $notifier_pid -ne 0 ]; then
    kill -s 9 $notifier_pid
  fi

  stopApp

  exit 0
}

restart() {
  trap - USR1
  echo "Restarting application..."
  lockBuild

  stopApp
  doRun
  unlockBuild

  if [ $tail_pid -ne 0 ]; then
    kill -s 9 $tail_pid
  fi

  trap 'restart' USR1

  tail -f /dev/null &
  tail_pid=$!
  wait $tail_pid
}

trap 'restart' USR1
trap 'shutDown' INT TERM

doRun

/inotifier.sh &
notifier_pid=$!

tail -f /dev/null &
tail_pid=$!
wait $tail_pid