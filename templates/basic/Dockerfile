FROM ubuntu:24.04

USER root
RUN apt update; apt -y upgrade

# kernel
RUN apt install -y linux-image-virtual

# init
RUN DEBIAN_FRONTEND=noninteractive apt install -y systemd-sysv

# network
RUN DEBIAN_FRONTEND=noninteractive apt install -y network-manager net-tools isc-dhcp-client iputils-ping netplan.io ifupdown

COPY ./10-globally-managed-devices.conf /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf

# boot
RUN cd /boot \
    && ln -fs vmlinuz-* vmlinuz \
    && ln -fs initrd.img-* initrd.img

# login
RUN echo "root:root" | chpasswd

# tools
RUN apt install -y nano
