#!/bin/bash
# restore a full backup of superbird device

# Superbird Partitions:

# Part      Start       Sectors  x  Size    Type    name
#  00       0           8192        512     U-Boot  bootloader  # only 4096 sectors used and writable
#  01       73728       131072      512     U-Boot  reserved
#  02       221184      0           512     U-Boot  cache
#  03       237568      16384       512     U-Boot  env
#  04       270336      8192        512     U-Boot  fip_a
#  05       294912      8192        512     U-Boot  fip_b
#  06       319488      16384       512     U-Boot  logo
#  07       352256      8192        512     U-Boot  dtbo_a
#  08       376832      8192        512     U-Boot  dtbo_b
#  09       401408      2048        512     U-Boot  vbmeta_a
#  10       419840      2048        512     U-Boot  vbmeta_b
#  11       438272      32768       512     U-Boot  boot_a
#  12       487424      32768       512     U-Boot  boot_b
#  13       536576      1056856     512     U-Boot  system_a
#  14       1609816     1056856     512     U-Boot  system_b
#  15       2683056     16384       512     U-Boot  misc
#  16       2715824     524288      512     U-Boot  settings
#  17       3256496     4378448     512     U-Boot  data

# on some devices, partition 17 is 4476752 sectors

############################################ Execution Guards #############################################################

# only works on x86_64 Linux
if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
    echo "The amlogic-usb-tool binary is only compatible with Linux x86_64 "
    echo "  This system is: $(uname -s) $(uname -m)"
    exit 1
fi

# need to be root
if [ "$(id -u)" != "0" ]; then
    echo "Must be run as root"
    exit 1
fi

set -e  # bail on any error

DIR=$(dirname "$(realpath "$0")")
UPDTOOL="${DIR}/amlogic-usb-tool"

BACKUP_DIR="$1"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Could not find: $BACKUP_DIR"
    exit 1
fi

announce() {
    echo ""
    echo "#####################################################################"
    echo "$*"
    echo "#####################################################################"
}

function restore_partition() {
    PART_NAME="$1"
    DUMP_FILE="$2"
    announce "Restoring $PART_NAME from $DUMP_FILE"
    $UPDTOOL mwrite "$DUMP_FILE" store "$PART_NAME" normal
}

$UPDTOOL bulkcmd "amlmmc part 1"

restore_partition "bootloader" "${BACKUP_DIR}/bootloader.dump"
restore_partition "env" "${BACKUP_DIR}/env.dump"
restore_partition "fip_a" "${BACKUP_DIR}/fip_a.dump"
restore_partition "fip_b" "${BACKUP_DIR}/fip_b.dump"
restore_partition "logo" "${BACKUP_DIR}/logo.dump"
restore_partition "dtbo_a" "${BACKUP_DIR}/dtbo_a.dump"
restore_partition "dtbo_b" "${BACKUP_DIR}/dtbo_b.dump"
restore_partition "vbmeta_a" "${BACKUP_DIR}/vbmeta_a.dump"
restore_partition "vbmeta_b" "${BACKUP_DIR}/vbmeta_b.dump"
restore_partition "boot_a" "${BACKUP_DIR}/boot_a.dump"
restore_partition "boot_b" "${BACKUP_DIR}/boot_b.dump"
restore_partition "misc" "${BACKUP_DIR}/misc.dump"
restore_partition "settings" "${BACKUP_DIR}/settings.ext4"
restore_partition "system_a" "${BACKUP_DIR}/system_a.ext2"
restore_partition "system_b" "${BACKUP_DIR}/system_b.ext2"

if [ -f "${BACKUP_DIR}/data.ext4" ]; then
    restore_partition "data" "${BACKUP_DIR}/data.ext4"
fi

echo "done restoring all partitions"