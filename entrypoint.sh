#!/bin/bash

# Ensure the SSH directory in the persistent volume exists
mkdir -p /var/lib/docker-borg/ssh > /dev/null 2>&1

# Generate host keys if not present (or not injected via Docker configs)
if [ ! -f /var/lib/docker-borg/ssh/ssh_host_rsa_key ]; then
    echo "Creating SSH keys. To persist keys across container updates, mount a volume to /var/lib/docker-borg..."
    ssh-keygen -A
    mv /etc/ssh/ssh*key* /var/lib/docker-borg/ssh/
fi

# Secure the host keys
chmod -R og-rwx /var/lib/docker-borg/ssh/

# Link persistent/injected keys back to the standard SSH configuration path
ln -sf /var/lib/docker-borg/ssh/* /etc/ssh > /dev/null 2>&1

# Dynamically adjust UID if provided via BORG_UID env var
if [ -n "${BORG_UID}" ]; then
    usermod -u "${BORG_UID}" borg
fi

# Dynamically adjust GID if provided via BORG_GID env var
if [ -n "${BORG_GID}" ]; then
    groupmod -o -g "${BORG_GID}" borg
    usermod -g "${BORG_GID}" borg
fi

# Inject authorized_keys from environment variable for GitOps/Portainer deployment
if [ ! -z ${BORG_AUTHORIZED_KEYS+x} ]; then
    echo -e "${BORG_AUTHORIZED_KEYS}" > /home/borg/.ssh/authorized_keys
    chown borg:borg /home/borg/.ssh/authorized_keys
    chmod og-rwx /home/borg/.ssh/authorized_keys
fi

# Ownership fix for the Virtual Env to allow the 'borg' user to execute the binary
chown -R borg:borg /opt/borg-env

# Final permission enforcement for borg directories
chown -R borg:borg /home/borg
chown -R borg:borg /home/borg/.ssh
chown -R borg:borg /var/backups/borg

# Launch SSH daemon in foreground
exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config
