# docker-borg-backup

A lightweight, secure, and multi-stage dockerized Borg Backup server.
For more information about Borg Backup, the excellent de-duplicating backup tool, refer to: [borgbackup.org](https://www.borgbackup.org/)

This image is heavily based on `tgbyte/borg-backup`, but optimized for modern container standards and size efficiency.

## 🚀 Key Differences & Features

* **Ultra-lightweight Base**: Built on **Alpine Linux 3.23** instead of Ubuntu.
* **Multi-Stage Build**: The final image contains only runtime binaries (no compilers, dev headers, or build artifacts), significantly reducing image size.
* **Python Sandbox**: Uses a Python Virtual Environment (`venv`) to isolate Borg and its dependencies, ensuring stability and preventing system package conflicts.
* **Multi-Arch Support**: Native builds available for `amd64`, `arm64`, and `arm/v7`.

## 🛠 Usage

### Fast Run (Docker CLI)

```bash
docker run -d \
  --name borg-backup \
  -e BORG_AUTHORIZED_KEYS="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..." \
  -e BORG_UID=1000 \
  -e BORG_GID=1000 \
  -e TZ=Europe/Rome \
  -v /path/to/backups:/var/backups/borg \
  -v /path/to/ssh_keys:/var/lib/docker-borg \
  -p 2222:22 \
  cobra1978/borg-backup
```

## Docker Compose (Recommended for Portainer/GitOps)

This image supports two ways to inject authorized SSH keys:
1. **Environment Variable**: Quickest for simple setups.
2. **Docker Config (Template)**: More secure and robust for GitOps/Portainer stacks. The entrypoint will automatically copy the keys from the template to the user's home directory during boot, ensuring correct ownership even if UIDs are changed.

```yaml
services:
  borg-server:
    image: ghcr.io/marcellopercoco/borg-backup:latest
    container_name: borg-server
    environment:
      - BORG_UID=1000
      - BORG_GID=1000
      - TZ=Europe/Rome
      # OPTION 1: Env Var
      - BORG_AUTHORIZED_KEYS=ssh-rsa AAAAB3Nza...
    configs:
      # OPTION 2: Docker Config (Template)
      - source: authorized_keys
        target: /etc/ssh/authorized_keys.template
    volumes:
      - borg_data:/var/backups/borg
      - borg_ssh:/var/lib/docker-borg
    ports:
      - "2222:22"
    restart: unless-stopped

configs:
  authorized_keys:
    external: true

volumes:
  borg_data:
  borg_ssh:
```

## ⚙️ Configuration Variables

| Variable | Description |
| :--- | :--- |
| `BORG_AUTHORIZED_KEYS` | (Optional) The public SSH key(s) allowed to connect. |
| `BORG_UID` | The User ID for the `borg` user. The script dynamically adjusts the user ID at boot to match this value. |
| `BORG_GID` | The Group ID for the `borg` user. |
| `TZ` | Sets the container timezone (e.g., `Europe/Rome`). |

### 🔑 SSH Key Injection Methods

The container searches for keys in the following order:
1. **Environment Variable**: If `BORG_AUTHORIZED_KEYS` is set, it is written to `/home/borg/.ssh/authorized_keys`.
2. **Config Template**: If a file exists at `/etc/ssh/authorized_keys.template`, its content is **appended** to the authorized keys.

This "Template Copy" approach allows the container to support **Dynamic UIDs** correctly, as the files in the home directory are managed by the container's entrypoint script rather than being direct read-only mounts.

SSH Host Keys: To persist the container's SSH server identity (host keys) across updates, mount a volume to /var/lib/docker-borg. If you skip this, clients will see a "Remote Host Identification Has Changed" warning after every container recreate.

## ⚠️ Important Notes on Persistence

1.  **Backup Data**: You **MUST** mount a volume to `/var/backups/borg`. If you do not, your backups will vanish when the container is removed or updated.
2.  **SSH Host Keys**: To persist the container's SSH server identity (host keys) across updates, mount a volume to `/var/lib/docker-borg`. If you skip this, clients will see a "Remote Host Identification Has Changed" warning after every container recreate.

## Supported Architectures

This image is available for:
* `linux/amd64`
* `linux/arm64`
* `linux/arm/v7`

## License

The files contained in this Git repository are licensed under the following license. This license explicitly does not cover the Borg Backup and Alpine Linux software packaged when running the Docker build. For these components, separate licenses apply that you can find at:

* [Borg Backup License](https://borgbackup.readthedocs.io/en/stable/authors.html#license)
* [Alpine Linux License](https://alpinelinux.org/license/)

**Copyright 2018-2023 TG Byte Software GmbH**
**Copyright 2024-2026 cobra1978**

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
