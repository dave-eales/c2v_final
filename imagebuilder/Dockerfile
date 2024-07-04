FROM ubuntu:24.04

RUN apt update; apt -y upgrade

RUN INTERACTION=noninteractive apt install -y fdisk extlinux tzdata net-tools qemu-utils docker.io

RUN mkdir /workspace

WORKDIR /workspace
