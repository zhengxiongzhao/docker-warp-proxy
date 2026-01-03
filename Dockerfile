FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive

ENV PROXY_PORT=1080 \
    TZ=Asia/Shanghai \
    LOG_LEVEL=error \
    FAMILIES_MODE=off \
    WARP_LICENSE=

RUN apt-get update && \
  apt-get install dbus curl gpg tzdata lsb-release iputils-ping -y && \
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
  apt-get update && \
  apt-get install cloudflare-warp -y --no-install-recommends  && \
  rm -rf /var/lib/apt/lists/*

# RUN mkdir -p /var/run/dbus && \
#   dbus-uuidgen --ensure && \
#   chmod 1777 /tmp && \
#   chown root:messagebus /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
  
# COPY --chmod=755 scripts /scripts
# COPY --chmod=644 configs/logrotate.conf /etc/logrotate.conf
# COPY --chmod=644 configs/supervisord.conf /etc/supervisor/supervisord.conf
# COPY --chmod=755 configs/start-gost.sh /usr/local/bin/start-gost.sh

# VOLUME ["/var/lib/cloudflare-warp"]

# CMD ["/usr/bin/supervisord"]

RUN curl -L https://github.com/go-gost/gost/releases/download/v3.2.6/gost_3.2.6_linux_amd64.tar.gz  | tar -xOzf - gost > /usr/local/bin/gost && chmod +x /usr/local/bin/gost

WORKDIR /app/
COPY --chmod=755 scripts/start.sh /app/start.sh

CMD [ "/bin/bash", "/app/start.sh" ]
