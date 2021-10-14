#!/bin/sh

if [ ! -f "/var/lib/clamav/main.cvd" ]; then
    freshclam -F --stdout
fi

freshclam -F -d --stdout &
exec clamd -F
