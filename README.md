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
This method is ideal for GitOps workflows where keys are injected via environment variables.

```yaml
services:
  borg-server:
    image: cobra1978/borg-backup:latest
    container_name: borg-server
    environment:
      # Paste the full public key(s) here. For multiple keys, use a newline separated string if supported, 
      # or manage via an external env file.
      - BORG_AUTHORIZED_KEYS=${BORG_AUTHORIZED_KEYS}
      - BORG_UID=1000
      - BORG_GID=1000
      - TZ=Europe/Rome
    volumes:
      # DATA VOLUME: Where backups are actually stored
      - borg_data:/var/backups/borg
      # CONFIG VOLUME: Persists SSH Host Keys (prevents "Host verification failed" on clients)
      - borg_ssh:/var/lib/docker-borg
    ports:
      - "2222:22"
    restart: unless-stopped

volumes:
  borg_data:
  borg_ssh:
```

## ⚙️ Configuration Variables

| Variable | Description |
| :--- | :--- |
| `BORG_AUTHORIZED_KEYS` | The public SSH key(s) allowed to connect. This populates `/home/borg/.ssh/authorized_keys`. |
| `BORG_UID` | The User ID for the `borg` user. Set this to match the owner of the mounted volume on the host to avoid permission issues. |
| `BORG_GID` | The Group ID for the `borg` user. |
| `TZ` | Sets the container timezone (e.g., `Europe/Rome`). |

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
