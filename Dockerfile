FROM alpine:3.20

ARG BORG_VERSION=1.4.0

RUN set -x \
	&& apk update \
	&& apk upgrade --no-cache \ 
	&& apk add --no-cache python3 py3-pip openssh-server bash shadow \
	&& apk add --no-cache \
	pkgconf \
	gcc \
	openssl-dev \
	lz4-dev \
	zstd-dev \
	xxhash-dev \
	acl-dev \
	python3-dev \
	libstdc++-dev \
	musl-dev \
	linux-headers \
	openssl \
	lz4-libs \
	zstd-libs \
	libxxhash \
	libacl \
	libstdc++ \ 
	&& pip3 install --break-system-packages -v "borgbackup==${BORG_VERSION}" \
	&& apk del \
	pkgconf \
	openssl-dev \
	lz4-dev \
	zstd-dev \
	xxhash-dev \
	acl-dev \
	gcc \
	python3-dev \
	libstdc++-dev \
	musl-dev \
	linux-headers \
	&& adduser --uid 500 --gecos "Borg Backup" -s /bin/bash -h /home/borg -D borg \
	&& usermod -p '*' borg \
	&& rm -f /etc/ssh/ssh_host_* \
	&& mkdir -p /var/run/sshd /var/backups/borg /var/lib/docker-borg/ssh mkdir /home/borg/.ssh \
	&& chown borg.borg /var/backups/borg /home/borg/.ssh \
	&& chmod 700 /home/borg/.ssh \
	&& rm -rf /root/.cache/pip \
	&& sed -i \
        -e 's/^#PasswordAuthentication yes$/PasswordAuthentication no/g' \
        -e 's/^PermitRootLogin without-password$/PermitRootLogin no/g' \
        -e 's/^X11Forwarding yes$/X11Forwarding no/g' \
        -e 's/^#LogLevel .*$/LogLevel ERROR/g' \
        /etc/ssh/sshd_config

VOLUME ["/var/backups/borg", "/var/lib/docker-borg"]

ADD ./entrypoint.sh /

EXPOSE 22

CMD ["/entrypoint.sh"]
