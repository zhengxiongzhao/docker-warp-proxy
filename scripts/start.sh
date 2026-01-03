#!/bin/bash
export GOST_LOGGER_LEVEL=${LOG_LEVEL:-error}
export GOMAXPROCS=$(nproc)
ulimit -n 65535

/usr/bin/warp-svc > /dev/null &

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
            warp-cli --accept-tos registration delete 2>/dev/null || true
            warp-cli --accept-tos registration new || true
        fi
    fi
else
    if [ -n "$current_license" ]; then
        echo "License exists: $current_license, skipping new registration."
    else
        echo "No License found, registering new..."
        warp-cli --accept-tos registration new || true
    fi
fi

# warp-cli --accept-tos proxy port "${PROXY_PORT}"
warp-cli --accept-tos mode proxy 2>/dev/null || true
warp-cli --accept-tos dns families "${FAMILIES_MODE:-off}" 2>/dev/null || true
warp-cli --accept-tos connect
warp-cli --accept-tos status

# wait $WARP_PID

gost -L "tcp://:${PROXY_PORT}/127.0.0.1:40000?keepalive=true&ttl=5s&readBufferSize=4096"  -L "udp://:${PROXY_PORT}/127.0.0.1:40000?keepalive=true&ttl=5s&readBufferSize=4096"
