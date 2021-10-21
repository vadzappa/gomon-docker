#!/bin/sh

timestmp() {
    date +'[%F %T] [gomon] '
}

GOMON_DIED_CHECK_INTERVAL=${GOMON_DIED_CHECK_INTERVAL-2}

if [ -z "${GOMON_DIED_CHECK_INTERVAL}" ] || [ "${GOMON_DIED_CHECK_INTERVAL}" -ne "${GOMON_DIED_CHECK_INTERVAL}" ] 2>/dev/null; then
  GOMON_DIED_CHECK_INTERVAL='2'
fi

notifyAppDied() {
    echo "$(timestmp)Application died, restarting..."
}

DEBUG_RETRIES="${GO_DEBUG_STARTUP_RETRIES}"
if [ -z "${GO_DEBUG_STARTUP_RETRIES}" ]; then
  DEBUG_RETRIES="6"
fi


runForever() {
  sleep 10
  IS_DEBUG="${1}"
  while [ -n "1" ]; do
    sleep $GOMON_DIED_CHECK_INTERVAL
    if [ "${IS_DEBUG}" = "true" ]; then
      if [ -z "$(pidof dlv)" ] || [ -z "$(pidof debug_bin)" ]; then
        j=0
        while [ $j -lt ${DEBUG_RETRIES} ]; do
            echo "$(timestmp)Something is not up, giving another try"
            sleep 10
            if [ "$(pidof dlv)" ] && [ "$(pidof debug_bin)" ]; then
              break
            fi
            j=$(( j + 1 ))
        done
        if [ "$(pidof dlv)" ] && [ "$(pidof debug_bin)" ]; then
          continue
        fi
        notifyAppDied
        kill -s USR1 1 &
      fi
    elif [ -z "$(pidof run_bin)" ]; then
      notifyAppDied
      kill -s USR1 1 &
    fi
  done
}

echo "$(timestmp)Checking if app is alive with interval ${GOMON_DIED_CHECK_INTERVAL}s"

runForever $1