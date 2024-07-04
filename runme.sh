#!/bin/bash

# List directories in the templates folder
template_dirs=(templates/*/)

# Prompt the user to select a directory
PS3="Please select the directory to build: "
select template_dir in "${template_dirs[@]}"; do
    if [[ -n $template_dir ]]; then
        echo "You selected $template_dir"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# Prompt the user for the disk size in MB with a default value of 2048
read -p "Please enter the disk size in MB (default: 2048): " disk_size_mb

# Set default value if input is empty
disk_size_mb=${disk_size_mb:-2048}

# Validate that the disk size is a number
if ! [[ "$disk_size_mb" =~ ^[0-9]+$ ]]; then
    echo "Error: Disk size must be a number"
    exit 1
fi

# Sanitize the template directory name to create a valid Docker tag
template_name=$(basename "$template_dir")
docker_tag="c2v_${template_name//\//_}"

# Build the imagebuilder docker container first
cd imagebuilder && docker build -t c2v/imagebuilder .
cd ..
mkdir -p output

# Build the selected directory
cd "$template_dir" || exit 1
docker build -t "$docker_tag" .
cd - || exit 1

# Set up the loop device
export LOOPDEV=$(losetup -f)

# Run the Docker container
docker run -it \
--env LOOPDEV=${LOOPDEV} \
-v /var/run/docker.sock:/var/run/docker.sock \
-v "$(pwd)":/workspace:rw \
--privileged \
--device ${LOOPDEV} \
c2v/imagebuilder \
bash dockerscripts/build.sh "$template_dir" "$disk_size_mb"
