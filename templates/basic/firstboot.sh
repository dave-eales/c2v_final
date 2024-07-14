#!/bin/bash

# Your firstboot actions here

# Example actions:
echo "Running actions for first boot..."

# Add your commands here
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Remove @reboot entry from /etc/crontab
echo "Removing @reboot entry from /etc/crontab..."
sed -i '/@reboot/d' /etc/crontab

# Delete this script file
echo "Deleting firstboot.sh script..."
rm -f "$0"
