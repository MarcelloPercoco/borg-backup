FROM archlinux/archlinux:latest

# instlal packages
RUN set -x \
	&& pacman -Syu --noconfirm \
	&& pacman -S extra/borg core/openssh --noconfirm \
	&& pacman -Scc --noconfirm

#prepare user env
RUN rm -f /etc/ssh/ssh_host_* \
	&& useradd -u 500 -U borg \
	&& mkdir -p /var/run/sshd /var/backups/borg /var/lib/docker-borg/ssh mkdir /home/borg/.ssh \
	&& chown borg:borg /var/backups/borg /home/borg/.ssh \
	&& chmod 700 /home/borg/.ssh 

#prepare ssh
RUN set -x \
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
