FROM ubuntu:24.04

USER root
RUN apt update; apt -y upgrade

# kernel
RUN apt install -y linux-image-virtual

# init
RUN DEBIAN_FRONTEND=noninteractive apt install -y systemd-sysv

# cron
RUN DEBIAN_FRONTEND=noninteractive apt install -y cron

# network
RUN DEBIAN_FRONTEND=noninteractive apt install -y network-manager net-tools isc-dhcp-client iputils-ping netplan.io ifupdown

# Copy NetworkManager configuration
COPY ./10-globally-managed-devices.conf /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf

# Copy Netplan configuration
COPY ./01-netcfg.yaml /etc/netplan/01-netcfg.yaml

# Set permissions on Netplan configuration
RUN chmod 600 /etc/netplan/01-netcfg.yaml

# Copy firstboot script
COPY ./firstboot.sh /root/firstboot.sh

# Add script to crontab so that it runs on first boot
RUN echo "@reboot root /bin/bash /root/firstboot.sh" >> /etc/crontab

# boot
RUN cd /boot \
    && ln -fs vmlinuz-* vmlinuz \
    && ln -fs initrd.img-* initrd.img

# login
RUN echo "root:root" | chpasswd

# tools
RUN apt install -y nano
