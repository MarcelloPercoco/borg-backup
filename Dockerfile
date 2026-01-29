ARG ALPINE_VERSION=3.23
FROM alpine:${ALPINE_VERSION} AS builder

# Set Borg version at build time
ARG BORG_VERSION=1.4.2

# Install build dependencies
RUN apk add --no-cache \
    python3 python3-dev py3-pip \
    gcc musl-dev linux-headers openssl-dev \
    lz4-dev zstd-dev xxhash-dev acl-dev pkgconf

# Create a Virtual Environment (venv) to isolate Borg and its dependencies
# This avoids using --break-system-packages on newer Alpine versions
RUN python3 -m venv /opt/borg-env && \
    /opt/borg-env/bin/pip install --upgrade pip setuptools wheel && \
    /opt/borg-env/bin/pip install "borgbackup==${BORG_VERSION}"

# ==============================================================================
# STAGE 2: Runtime
# ==============================================================================
FROM alpine:${ALPINE_VERSION}

LABEL maintainer="Gemini Adaptive AI"
ENV TZ=Europe/Rome
# Add the venv bin directory to PATH so 'borg' is available globally
ENV PATH="/opt/borg-env/bin:$PATH"

# Install only necessary runtime libraries and services
RUN apk add --no-cache \
    python3 \
    bash shadow openssh-server \
    tzdata openssl lz4-libs zstd-libs libxxhash acl

# Copy the pre-compiled Borg environment from the builder stage
COPY --from=builder /opt/borg-env /opt/borg-env

# Create the 'borg' user and required directory structure
RUN adduser --uid 500 --gecos "Borg Backup" -s /bin/bash -h /home/borg -D borg && \
    usermod -p '*' borg && \
    mkdir -p /var/run/sshd /var/backups/borg /var/lib/docker-borg/ssh /home/borg/.ssh && \
    chown borg:borg /var/backups/borg /home/borg/.ssh

# SSH Hardening: Disable password auth and root login
RUN sed -i \
    -e 's/^#PasswordAuthentication yes/PasswordAuthentication no/' \
    -e 's/^#PermitRootLogin.*/PermitRootLogin no/' \
    -e 's/^#LogLevel.*/LogLevel ERROR/' \
    /etc/ssh/sshd_config

# Security symlink to ensure SSH sessions find the borg binary regardless of ENV
RUN ln -s /opt/borg-env/bin/borg /usr/local/bin/borg

# Persistence volumes
VOLUME ["/var/backups/borg", "/var/lib/docker-borg"]

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"] 
