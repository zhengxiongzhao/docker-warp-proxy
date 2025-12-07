#!/bin/bash

# --- 1. 定义 IPC 就绪检查函数 ---
function wait_for_ipc {
    MAX_ATTEMPTS=40  # 增加尝试次数以覆盖 Supervisor 的启动时间
    attempt_counter=0
    # 检查 warp-svc IPC 是否响应
    until warp-cli status &> /dev/null; do
        echo "Waiting for warp-svc IPC to be ready... Attempt $attempt_counter/$MAX_ATTEMPTS"
        sleep 1
        if [ $attempt_counter -ge $MAX_ATTEMPTS ]; then
            echo "CRITICAL: IPC failed to respond. Shutting down."
            return 1
        fi
        attempt_counter=$((attempt_counter + 1))
    done
    return 0
}

# -----------------------------------------------
# 核心配置逻辑
# -----------------------------------------------

# 确保 warp-svc-core 已经启动并监听 IPC
if ! wait_for_ipc; then
    echo "ERROR: IPC Timeout. Aborting configuration." 
    exit 1  # 立即退出，避免 Supervisor FATAL
fi
echo "IPC Ready. Starting configuration."


# --- 1. 配置 WARP 模式 (如果 warp-cli 无法连接，它会失败) ---
echo "Starting WARP configuration..."

# --- 2. 许可证/注册逻辑 (如果许可证存在，则应用许可证) ---

if [[ -n $WARP_LICENSE ]]; then
  echo "Applying license key..."
  
  # 尝试设置许可证
  if warp-cli --accept-tos registration license "${WARP_LICENSE}"; then
      echo "License applied successfully."
  else
      # --- 许可证设置失败的回退逻辑 ---
      echo "WARN: License application failed. ($?)"
      echo "Attempting to reset registration and use free WARP mode..."
      
      # 尝试注销旧的/失败的注册，并执行新的免费注册
      # 如果注销失败则忽略，但必须尝试新注册
      warp-cli registration delete 2>/dev/null || true 
      
      if warp-cli --accept-tos registration new; then
          echo "SUCCESS: Successfully registered for free WARP."
      else
          echo "CRITICAL ERROR: Failed to register for free WARP. Cannot proceed."
          exit 1 # 无法注册，脚本退出失败
      fi
  fi
else
  echo "No license key provided. Attempting free registration..."
  if ! warp-cli --accept-tos registration new; then
      echo "CRITICAL ERROR: Failed to register for free WARP. Cannot proceed."
      exit 1 # 无法注册，脚本退出失败
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