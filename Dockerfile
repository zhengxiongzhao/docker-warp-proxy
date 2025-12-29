FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive

ENV PROXY_PORT=1080 \
    TZ=Asia/Shanghai \
    FAMILIES_MODE=off \
    WARP_LICENSE=

EXPOSE 1080/tcp

RUN apt-get update && \
  apt-get install dbus curl gpg tzdata lsb-release supervisor logrotate unzip git -y && \
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
  apt-get update && \
  apt-get install cloudflare-warp -y --no-install-recommends  && \
  mkdir -p /usr/local/bin && \
  curl -L https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost_2.12.0_linux_amd64.tar.gz \
  | tar -xOzf - gost > /usr/local/bin/gost && chmod +x /usr/local/bin/gost && \
  rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/dbus && \
  dbus-uuidgen --ensure && \
  chmod 1777 /tmp && \
  chown root:messagebus /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
  
COPY --chmod=755 scripts /scripts
COPY --chmod=644 configs/logrotate.conf /etc/logrotate.conf
COPY --chmod=644 configs/supervisord.conf /etc/supervisor/supervisord.conf
COPY --chmod=755 configs/start-gost.sh /usr/local/bin/start-gost.sh

VOLUME ["/var/lib/cloudflare-warp"]

CMD ["/usr/bin/supervisord"]