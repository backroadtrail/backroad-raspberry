#!/usr/bin/env bash

# Copyright 2020 OpsResearch LLC
#
# This file is part of Backroad Raspberry.
#
# Backroad Raspberry is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Backroad Raspberry is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Backroad Raspberry.  If not, see <https://www.gnu.org/licenses/>.
##

# BASH BOILERPLATE
set -euo pipefail
IFS=$'\n\t'
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$HERE"
source "config.sh"
source "funct.sh"
##

usage(){
    echo "Usage: $0 <disk-device> <image-directory> <image-base-name>"
    exit 1
}

export image_base_name=new_image

if [  $# -ne 3 ]; then
	usage
fi 

# ARGUMENTS
export disk="$1"
export p1="${disk}1"
export p2="${disk}2"
export image_dir="$2"
export image_base="$3"

# VALIDATE DISK DEVICE
if [ ! -b "$disk" ]; then
    echo "The disk device: $disk either doesn't exist or isn't a block device!"
    usage
fi

if [ ! -b "$p1" ]; then
    echo "The disk partition: $p1 either doesn't exist or isn't a block device!"
    usage
fi

if [ ! -b "$p2" ]; then
    echo "The disk partition: $p2 either doesn't exist or isn't a block device!"
    usage
fi

# GET THE START OF PARTITION 2
start="$(sudo fdisk -l "$disk" | grep "$p2" | tr -s ' ' | cut -d ' ' -f2)"
echo "Start = $start"

# CHECK THE FILESYSTEM
sudo e2fsck -f -y -v -C 0 "$p2"

# RESIZE THE FILESYSTEM
blocks="$(sudo resize2fs -M -p "$p2" 2>&1 | grep '(4k)' | sed 's/^.* \([0-9]\+\).*[(]4k[)].*$/\1/g')"
echo "Blocks=$blocks"

# RESIZE THE PARTITION
kilobytes="${blocks * 4}"
echo "Kilobytes=$kilobytes"
sudo fdisk "$disk" <<EOF
d
2
n
p
2
$start
+${kilobytes}K

w
EOF

# FIND THE END OF THE FILESYSTEM
end="$(sudo fdisk -l "$disk" | grep "$p2" | tr -s ' ' | cut -d ' ' -f3)"
echo "End = $end"

# THE NUMBER OF SECTORS TO COPY
count="${end + 1}"
echo "Count = $count"

# COPY THE IMAGE
cd "$image_dir"
sudo dcfldd bs=512 count="$count" if="$disk" of="${image_base}.img"
sudo chown pi:pi "${image_base}.img"

# COMPRESS THE IMAGE AND CLEANUP
zip "${image_base}.zip" "${image_base}.img"
rm "${image_base}.img"

echo "The new image is here: $$image_dir/${image_base}.zip"

