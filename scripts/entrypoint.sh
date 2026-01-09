#!/bin/bash
set -e

export GOST_LOGGER_LEVEL=${LOG_LEVEL:-error}
export GOMAXPROCS=$(nproc)
ulimit -n 65535

if [ ! -e /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

mkdir -p /run/dbus
if [ -f /run/dbus/pid ]; then
    rm /run/dbus/pid
fi
dbus-daemon --config-file=/usr/share/dbus-1/system.conf


/usr/bin/warp-svc --accept-tos > /dev/null &

WARP_PID=$!

sleep 5

current_license=$(warp-cli --accept-tos registration show | grep 'License:' | awk '{print $2}' || echo "")

if [ -n "$WARP_LICENSE" ]; then
    if [ "$current_license" = "$WARP_LICENSE" ]; then
        echo "Current License matches $WARP_LICENSE, no need to re-register."
    else
        echo "Applying License key..."
        if warp-cli --accept-tos registration license "$WARP_LICENSE" | grep -q "Success"; then
            echo "License applied successfully."
        else
            echo "License failed, registering new..."
            warp-cli --accept-tos registration delete > /dev/null || true
            warp-cli --accept-tos registration new  > /dev/null || true
        fi
    fi
else
    if [ -n "$current_license" ]; then
        echo "License exists: $current_license, skipping new registration."
    else
        echo "No License found, registering new..."
        warp-cli --accept-tos registration new  > /dev/null || true
    fi
fi

# warp-cli --accept-tos proxy port "${PROXY_PORT}"
warp-cli --accept-tos mode proxy > /dev/null || true
warp-cli --accept-tos dns families "${FAMILIES_MODE:-off}" > /dev/null || true
warp-cli --accept-tos connect > /dev/null || true
warp-cli --accept-tos status

# wait $WARP_PID

gost -L "tcp://:${PROXY_PORT}/127.0.0.1:40000?keepalive=true&ttl=5s&readBufferSize=4096"  -L "udp://:${PROXY_PORT}/127.0.0.1:40000?keepalive=true&ttl=5s&readBufferSize=4096"
