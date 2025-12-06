#!/bin/bash
set -m
warp-svc > >(grep -iv dbus) 2> >(grep -iv dbus >&2) &
WARP_PID=$!
sleep 2
warp-cli --accept-tos registration new
warp-cli --accept-tos proxy port 40000
warp-cli --accept-tos mode proxy
warp-cli --accept-tos debug qlog disable
warp-cli --accept-tos dns log disable
warp-cli --accept-tos dns families "${FAMILIES_MODE}"
if [[ -n $WARP_LICENSE ]]; then
  warp-cli --accept-tos registration license "${WARP_LICENSE}"
fi
warp-cli --accept-tos connect
warp-cli --accept-tos status
socat tcp-listen:${PROXY_PORT},reuseaddr,fork tcp:localhost:40000 &
wait $WARP_PID
