#!/bin/sh

# Ensure the SSH directory in the persistent volume exists
mkdir -p /var/lib/docker-borg/ssh > /dev/null 2>&1

# Generate host keys se non esistono (o non sono iniettate tramite configs)
if [ ! -f /var/lib/docker-borg/ssh/ssh_host_rsa_key ]; then
    echo "Creating SSH keys. To persist keys across container updates, mount a volume to /var/lib/docker-borg..."
    ssh-keygen -A
    mv /etc/ssh/ssh*key* /var/lib/docker-borg/ssh/
fi

# Secure the host keys
chmod -R og-rwx /var/lib/docker-borg/ssh/

# Link persistente all'SSH config standard path
ln -sf /var/lib/docker-borg/ssh/* /etc/ssh > /dev/null 2>&1

# Dynamically adjust UID se flaggato via env
if [ -n "${BORG_UID}" ]; then
    usermod -u "${BORG_UID}" borg
fi

# Dynamically adjust GID se flaggato via env
if [ -n "${BORG_GID}" ]; then
    groupmod -o -g "${BORG_GID}" borg
    usermod -g "${BORG_GID}" borg
fi

# Handle authorized_keys (from environment variable or config template)
mkdir -p /home/borg/.ssh
chmod 700 /home/borg/.ssh

# Start with an empty or existing file
: > /home/borg/.ssh/authorized_keys

# 1. Use the environment variable if present (takes priority)
if [ -n "${BORG_AUTHORIZED_KEYS+x}" ]; then
    printf '%s\n' "${BORG_AUTHORIZED_KEYS}" >> /home/borg/.ssh/authorized_keys
fi

# 2. Append from the config template if it was mounted
if [ -f /etc/ssh/authorized_keys.template ]; then
    cat /etc/ssh/authorized_keys.template >> /home/borg/.ssh/authorized_keys
fi

# Ensure correct permissions and ownership (after the UID adjustment)
chown borg:borg /home/borg/.ssh/authorized_keys
chmod 600 /home/borg/.ssh/authorized_keys

# (Il chown inutilmente lento su /opt/borg-env è stato opportunamente rimosso)

# Final permission enforcement solo per le borg directories dell'utente
chown -R borg:borg /home/borg
chown -R borg:borg /var/backups/borg

# Launch SSH daemon in foreground
exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config