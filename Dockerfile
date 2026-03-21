ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} AS builder

# Set Borg version at build time
ARG BORG_VERSION

# Install build dependencies
RUN apk upgrade --no-cache && \
    apk add --no-cache \
    python3 python3-dev py3-pip \
    gcc musl-dev linux-headers openssl-dev \
    lz4-dev zstd-dev xxhash-dev acl-dev pkgconf

# Create a Virtual Environment (venv) to isolate Borg and its dependencies
RUN python3 -m venv /opt/borg-env && \
    /opt/borg-env/bin/pip install --upgrade pip setuptools wheel && \
    /opt/borg-env/bin/pip install "borgbackup==${BORG_VERSION}"

# ==============================================================================
# STAGE 2: Runtime
# ==============================================================================
FROM alpine:${ALPINE_VERSION}

LABEL maintainer="Gemini Adaptive AI"
ENV TZ=Europe/Rome \
    PATH="/opt/borg-env/bin:$PATH"

# Installa runtime essentials in ordine alfabetico e nativamente senze 'bash'
RUN apk upgrade --no-cache && \
    apk add --no-cache \
    acl libxxhash lz4-libs openssh-server openssl python3 shadow tzdata zstd-libs

# Copia dal builder all'ambiente di runtime
COPY --from=builder /opt/borg-env /opt/borg-env

# Accorpamento di setup utente (usando /bin/sh!), ssh hardening e binding di sistema in un solo layer "sporco"
RUN adduser --uid 500 --gecos "Borg Backup" -s /bin/sh -h /home/borg -D borg && \
    usermod -p '*' borg && \
    mkdir -p /var/run/sshd /var/backups/borg /var/lib/docker-borg/ssh /home/borg/.ssh && \
    chown borg:borg /var/backups/borg /home/borg/.ssh && \
    sed -i \
    -e 's/^#PasswordAuthentication yes/PasswordAuthentication no/' \
    -e 's/^#PermitRootLogin.*/PermitRootLogin no/' \
    -e 's/^#LogLevel.*/LogLevel ERROR/' \
    /etc/ssh/sshd_config && \
    ln -s /opt/borg-env/bin/borg /usr/local/bin/borg

# Persistence volumes
VOLUME ["/var/backups/borg", "/var/lib/docker-borg"]

# Copia e assegna i permessi all'entrypoint via buildkit anziché creando layer intermediati 'RUN'
COPY --chmod=755 ./entrypoint.sh /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"] 