#!/bin/bash

# --- 1. 配置 WARP 模式 (如果 warp-cli 无法连接，它会失败) ---
echo "Starting WARP configuration..."

# --- 2. 许可证/注册逻辑 (如果许可证存在，则应用许可证) ---

if [[ -n $WARP_LICENSE ]]; then
  echo "Applying license key..."
  warp-cli --accept-tos registration license "${WARP_LICENSE}"
else
  echo "Attempting free registration..."
  warp-cli --accept-tos registration new
fi

set -e 

# Set the proxy port to 40000
warp-cli --accept-tos proxy port 40000

# Set the mode to proxy
warp-cli --accept-tos mode proxy

# Disable DNS log
warp-cli --accept-tos dns log disable

# Set the families mode based on the value of the FAMILIES_MODE variable
warp-cli --accept-tos dns families "${FAMILIES_MODE}"

# Connect to the WARP service
warp-cli --accept-tos connect

# Check if warp-cli is connected
warp-cli --accept-tos status

exit 0