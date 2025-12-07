#!/bin/bash

set -e

# Kill any existing instances of warp-svc before starting a new one
if pkill -x warp-svc -9; then
  echo "Existing warp-svc process killed."
fi


# 启动 WARP 核心服务 (后台)
warp-svc > >(grep -iv dbus) 2> >(grep -iv dbus >&2) &
WARP_PID=$!
echo "Initial wait: Sleeping for ${WARP_SLEEP} seconds..."
sleep "$WARP_SLEEP"

# 信号处理
trap "echo 'Stopping warp-svc...'; kill -TERM $WARP_PID; wait $WARP_PID; exit" SIGTERM SIGINT

# --- 关键函数：等待 IPC 就绪 (通用检查) ---
function wait_for_ipc {
  MAX_ATTEMPTS=10
  attempt_counter=0
  echo "Waiting for warp-svc IPC socket..."
  until warp-cli status &> /dev/null; do
    sleep 1
    if [[ $attempt_counter -ge $MAX_ATTEMPTS ]]; then
      echo "CRITICAL ERROR: warp-svc IPC never came up. Exiting."
      return 1
    fi
    attempt_counter=$((attempt_counter + 1))
  done
  return 0
}

# --- 1. 等待核心服务就绪 ---
if ! wait_for_ipc; then
  kill $WARP_PID
  exit 1
fi
echo "warp-svc IPC ready."

# --- 2. 许可证/注册逻辑 (如果许可证存在，则应用许可证) ---

if [[ -n $WARP_LICENSE ]]; then
  echo "Applying license key..."
  # 尝试设置许可证。如果许可证已存在且有效，这会成功。
  # 如果许可证不存在，这会尝试注册。
  if ! warp-cli --accept-tos registration license "${WARP_LICENSE}"; then
      echo "ERROR: Failed to apply license. Check key validity."
      # 即使设置失败，我们也不立即退出，尝试继续配置。
  fi
else
  # 如果没有许可证，尝试使用免费注册
  echo "No license key provided. Attempting free registration..."
  if ! warp-cli --accept-tos registration new; then
      echo "ERROR: Free registration failed."
      kill $WARP_PID
      exit 1
  fi
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

socat tcp-listen:${PROXY_PORT},reuseaddr,fork tcp:localhost:40000 &

# Wait for warp-svc process to finish
wait $WARP_PID
