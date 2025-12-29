# warp-svc

[![Publish Docker image to Docker Hub](https://img.shields.io/badge/Publish%20Docker%20image%20to%20Docker%20Hub-latest-g?logo=docker)](https://hub.docker.com/r/zhengxiongzhao/warp-svc) 
[![Docker Pulls](https://img.shields.io/docker/pulls/zhengxiongzhao/warp-svc)](https://hub.docker.com/r/zhengxiongzhao/warp-svc)


> **使用最新版本的`warp-svc`编译， 版本号：2025.9.558.0**  

> **必要条件： 需要国际网络访问，才能使用！！！**

```
# https://github.com/shaonianche/warp-clash-api?tab=readme-ov-file
# https://github.com/TunMax/canal/tree/master

curl -x socks5h://127.0.0.1:1080 -sL https://cloudflare.com/cdn-cgi/trace | grep warp
```

将 Cloudflare WARP 客户端作为 docker 中的 socks5 服务器

这个 dockerfile 会创建一个带有适用于 Linux 的 Cloudflare WARP 官方客户端的 docker 镜像，并提供一个 socks5 代理服务器，以便在本地计算机或 docker compose 或 Kubernetes 中的其他 docker 容器中的其他兼容应用程序中使用。

适用于 Linux 的 Cloudflare WARP 官方客户端只在 localhost 上侦听 socks 代理，因此无法在需要绑定到 0.0.0.0 的 docker 容器中使用。

## Features
* 注册新的 Cloudflare WARP 账户
* 可配置的 "家庭模式
* 订阅 Cloudflare WARP+

## How to use
socks 代理的端口为 `1080`。

你可以使用这些环境变量：

* `families_mode`：使用`off`、`malware`和`full`值之一。(默认值：`off）

* `warp_license`：放置您的 WARP+ 许可证。(你可以从这个电报机器人获取免费的 WARP+ 许可证：https://t.me/generatewarpplusbot）

应将容器中的 `/var/lib/cloudflare-warp`目录挂载到主机上，以确保 WARP 账户的持久性。请注意，每个 WARP+ 许可证只能在 4 台设备上运行，因此持久化配置非常重要！

### Using as a local proxy with Docker
```
docker run -d --name=warp -e FAMILIES_MODE=full -e WARP_LICENSE=xxxxxxxx-xxxxxxxx-xxxxxxxx -p 127.0.0.1:1080:1080 -v ${PWD}/warp:/var/lib/cloudflare-warp zhengxiongzhao/warp-svc:latest
```
You can verify warp by visiting this url:
```
curl -x socks5h://127.0.0.1:1080 -sL https://cloudflare.com/cdn-cgi/trace | grep warp

warp=on
```
You can also use `warp-cli` command to control your connection:
```
docker exec warp warp-cli --accept-tos status

Status update: Connected
Success
```
### Using as a proxy for other containers with docker-compose

> WARP 需要创建一个虚拟网卡 (TUN 设备)

**你需要确保 Docker 容器是用以下参数启动的**

    --device /dev/net/tun: 允许容器访问宿主机的 TUN 设备。
    --cap-add NET_ADMIN: 允许容器修改网络配置（创建网卡、修改路由表）。

```
# 宿主机开启转发
sysctl -w net.ipv4.ip_forward=1

# 宿主机防火墙允许伪装（RHEL 9 必须）
firewall-cmd --zone=public --add-masquerade --permanent

# 宿主机检查状态
lsmod | grep -E "nf_conntrack|tun"

# 加载模块
modprobe nf_conntrack
modprobe tun

# 设置自动加载
echo -e "nf_conntrack\ntun" > /etc/modules-load.d/custom-modules.conf

# 检查
ls -l /dev/net/tun
```

```
version: "3"
services:
  warp:
    image: zhengxiongzhao/warp-svc:latest
    ports:
      - 1080:1080
    restart: always
    privileged: true
    device:
      - /dev/net/tun
    cap-add:
      - NET_ADMIN
    dns:
      - 1.1.1.1
      - 8.8.8.8
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv6.conf.all.disable_ipv6=0
    environment:
      - PROXY_PORT=1080
      - WARP_LICENSE=
      - FAMILIES_MODE=off
    volumes:
      - ./warp:/var/lib/cloudflare-warp
```

