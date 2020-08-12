#!/bin/sh
GOMON_IGNORE=${GOMON_IGNORE-''}

if [ "${GOMON_IGNORE}" = '' ]; then
  EXCLUDE_REGEX=''
else
  EXCLUDE_REGEX="--exclude ${GOMON_IGNORE}"
fi

timestmp() {
    date +'[%F %T] [gomon] '
}

inotifywait $EXCLUDE_REGEX -e MODIFY -e DELETE -q -r -m /app 2>/dev/null |
  while read -r path action file; do
    ext="${file##*.}"
    if [ "${ext}" != "go" ]; then
      continue
    fi
    echo "$(timestmp)${action}-ed ${file}"
    kill -s USR1 1 &
  done
