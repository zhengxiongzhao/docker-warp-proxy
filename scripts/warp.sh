#!/bin/bash
set -e

echo "Waiting for Warp daemon..."
for i in {1..30}; do
    if warp-cli status >/dev/null 2>&1; then
        echo "Warp daemon is ready."
        break
    fi
    echo "Daemon not ready yet, waiting 1s..."
    sleep 1
done

warp-cli --accept-tos registration delete 2>/dev/null || true

# 检查当前 License 是否和环境变量一致
current_license=$(warp-cli --accept-tos registration show | grep 'License:' | awk '{print $2}' || echo "")

if [ -n "$WARP_LICENSE" ]; then
    if [ "$current_license" = "$WARP_LICENSE" ]; then
        echo "Current License matches \$WARP_LICENSE, no need to re-register."
    else
        echo "Applying License key..."
        if warp-cli --accept-tos registration license "$WARP_LICENSE" | grep -q "Success"; then
            echo "License applied successfully."
        else
            echo "License failed, registering new..."
            warp-cli --accept-tos registration new || true
        fi
    fi
else
    # 如果没有环境变量 License，注册新
    if [ -n "$current_license" ]; then
        echo "License exists: $current_license, skipping new registration."
    else
        echo "No License found, registering new..."
        warp-cli --accept-tos registration new || true
    fi
fi


# Set the proxy port to 40000
warp-cli --accept-tos proxy port 40000

# Set the mode to proxy
warp-cli --accept-tos mode proxy

# Disable DNS log
warp-cli --accept-tos dns log disable

# Set the families mode based on the value of the FAMILIES_MODE variable
warp-cli --accept-tos dns families "${FAMILIES_MODE}"


# Check if warp-cli is connected
warp-cli --accept-tos connect || { 
    echo "CRITICAL: WARP Connect Failed!"
    exit 1
}

warp-cli --accept-tos status || { 
    echo "CRITICAL: WARP Status Check Failed!"
    exit 1
}

exit 0