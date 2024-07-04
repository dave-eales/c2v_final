#!/bin/bash

# Enable tracing for debugging
set -x

# Function to print an error message and exit
error_exit() {
    echo "Error: $1"
    exit 1
}

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <template_path> <partition_mb>"
    exit 1
fi

TEMPLATE_PATH=$1
PARTITION_MB=$2

# Validate that PARTITION_MB is a number
if ! [[ "$PARTITION_MB" =~ ^[0-9]+$ ]]; then
    error_exit "partition_mb must be a number"
fi

# Perform calculations and output their results
PARTITION_SIZE_DD=$(expr ${PARTITION_MB} \* 1024) || error_exit "Failed to calculate PARTITION_SIZE_DD"
echo "PARTITION_SIZE_DD (Partition size in dd): ${PARTITION_SIZE_DD} bytes"

# Convert MB to sectors (1 sector = 512 bytes, 1 MB = 2048 sectors)
PARTITION_SIZE_SECTORS=$(expr ${PARTITION_MB} \* 2048) || error_exit "Failed to calculate PARTITION_SIZE_SECTORS"
echo "PARTITION_SIZE_SECTORS (Partition size in sectors): ${PARTITION_SIZE_SECTORS}"

LOOP_OFFSET=$(expr 512 \* 2048) || error_exit "Failed to calculate LOOP_OFFSET"
echo "LOOP_OFFSET: ${LOOP_OFFSET}"

# Calculate image size (add some buffer to ensure there is enough space)
IMAGE_SIZE=$(expr ${PARTITION_SIZE_SECTORS} + 4096) || error_exit "Failed to calculate IMAGE_SIZE"
echo "IMAGE_SIZE (Image size in sectors): ${IMAGE_SIZE}"

# Sanitize the template directory name to create a valid Docker tag
template_name=$(basename "$TEMPLATE_PATH")
docker_tag="c2v_${template_name//\//_}"

echo -e "\nBuilding image from template: $TEMPLATE_PATH"
cd "$TEMPLATE_PATH" || error_exit "Failed to change directory to $TEMPLATE_PATH"
docker build -t "$docker_tag" . || error_exit "Failed to build Docker image"
cd - || error_exit "Failed to change back to previous directory"

echo -e "\nExporting image:"
docker export -o ./output/containercontents.tar $(docker run -d "$docker_tag" /bin/true) || error_exit "Failed to export Docker image"

echo -e "\nCreating partition in image file:"
mkdir -p ./output || error_exit "Failed to create output directory"

cat > ./output/partition.txt <<EOL
label: dos
label-id: 0x6332766d
device: linux.img
unit: sectors

linux.img1 : start=2048, size=${PARTITION_SIZE_SECTORS}, type=83, bootable
EOL

echo "Partition layout file created at ./output/partition.txt"

# Create an image file with the calculated size
dd if=/dev/zero of=./output/linux.img bs=512 count=${IMAGE_SIZE} || error_exit "Failed to create image file with dd"
echo "Image file created at ./output/linux.img with size ${IMAGE_SIZE} sectors"

# Partition the image file
sfdisk ./output/linux.img < ./output/partition.txt || error_exit "Failed to partition the image file with sfdisk"
echo "Partitioning completed successfully"

echo -e "\nCreating filesystem in loopback device:"
losetup -D || error_exit "Failed to detach all loop devices"
losetup -o ${LOOP_OFFSET} ${LOOPDEV} ./output/linux.img || error_exit "Failed to set up loop device"
mkfs.ext4 ${LOOPDEV} || error_exit "Failed to create filesystem"

if [[ ! -d ./output/mnt ]]; then
    mkdir -p ./output/mnt || error_exit "Failed to create mount directory"
fi
mount -t auto ${LOOPDEV} ./output/mnt/ || error_exit "Failed to mount loop device"

echo -e "\nCopying files to mounted loop disk root:"
tar -xf ./output/containercontents.tar -C ./output/mnt || error_exit "Failed to extract tar file"

echo -e "\nConfiguring extlinux:"
extlinux --install ./output/mnt/boot/ || error_exit "Failed to install extlinux"
cp ./imagebuilder/syslinux.cfg ./output/mnt/boot/syslinux.cfg || error_exit "Failed to copy syslinux.cfg"

umount ./output/mnt || error_exit "Failed to unmount loop device"
losetup -D || error_exit "Failed to detach all loop devices"

echo -e "\nCreating master boot record:"
dd if=/usr/lib/syslinux/mbr/mbr.bin of=./output/linux.img bs=440 count=1 conv=notrunc || error_exit "Failed to write MBR"

echo -e "\nConverting IMG to VMDK format:"
qemu-img convert -O vmdk ./output/linux.img ./output/linux.vmdk || error_exit "Failed to convert IMG to VMDK"

echo -e "\nCleaning Up:"
rm ./output/linux.img || error_exit "Failed to remove linux.img"
rm ./output/containercontents.tar || error_exit "Failed to remove containercontents.tar"
rm -rf ./output/mnt || error_exit "Failed to remove mount directory"
rm ./output/partition.txt || error_exit "Failed to remove partition.txt"

echo -e "\nBuild complete: ./output/linux.vmdk"

# Disable tracing
set +x
