#!/bin/bash
# create a full backup of superbird device
#   usage: ./dump-device.sh <backup-name>

# Superbird Partitions:

# Part      Start       Sectors  x  Size    Type    name
#  00       0           8192        512     U-Boot  bootloader # only 4096 sectors used and writable
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


############################################ Initialize Variables #########################################################

# default backup name
BACKUP_NAME="dump-$(date "+%Y%m%d_%H%M%S")"

# if we pass a name in, we generate a backup name that includes it
if [ -n "$1" ]; then
    BACKUP_NAME="custom-${1}-$(date "+%Y%m%d_%H%M%S")"
fi

DIR=$(dirname "$(realpath "$0")")
UPDTOOL="${DIR}/amlogic-usb-tool"
DUMPS_DIR="${DIR}/dumps"  # this folder is .gitignored

BACKUP_DIR="${DUMPS_DIR}/${BACKUP_NAME}"  # this is where THIS current backup will be stored

############################################ Helper Functions #############################################################

announce() {
    echo ""
    echo "#####################################################################"
    echo "$*"
    echo "#####################################################################"
}

bail() {
    echo "An error occured, and your backup may be incomplete"
    exit 1
}

backup_partition() {
    # dump a partition to a file
    PART_NAME="$1"
    PART_SIZE="$2"
    DEST_FILE="$3"
    announce "Dumping partition: $PART_NAME size: $PART_SIZE"
    $UPDTOOL mread store "$PART_NAME" normal "$PART_SIZE" "$DEST_FILE" || {
        echo "Error: failed to backup partition: $PART_NAME"
        bail
    }
}

############################################ Entrypoint ###################################################################

announce "Creating Backup in: $BACKUP_DIR"

# create folders as needed
mkdir -p "$DUMPS_DIR"
mkdir "$BACKUP_DIR" || {
    # since backups include a timestamp, this is incredibly unlikely
    echo "Error while creating ${BACKUP_DIR}, maybe it already exists?"
    bail

}

# start dumping stuff
$UPDTOOL bulkcmd "amlmmc part 1"
backup_partition "bootloader" 0x200000 "${BACKUP_DIR}/bootloader.dump"
backup_partition "env" 0x800000 "${BACKUP_DIR}/env.dump"
backup_partition "fip_a" 0x400000 "${BACKUP_DIR}/fip_a.dump"
backup_partition "fip_b" 0x400000 "${BACKUP_DIR}/fip_b.dump"
backup_partition "logo" 0x800000 "${BACKUP_DIR}/logo.dump"
backup_partition "dtbo_a" 0x400000 "${BACKUP_DIR}/dtbo_a.dump"
backup_partition "dtbo_b" 0x400000 "${BACKUP_DIR}/dtbo_b.dump"
backup_partition "vbmeta_a" 0x100000 "${BACKUP_DIR}/vbmeta_a.dump"
backup_partition "vbmeta_b" 0x100000 "${BACKUP_DIR}/vbmeta_b.dump"
backup_partition "boot_a" 0x1000000 "${BACKUP_DIR}/boot_a.dump"
backup_partition "boot_b" 0x1000000 "${BACKUP_DIR}/boot_b.dump"
backup_partition "misc" 0x800000 "${BACKUP_DIR}/misc.dump"

backup_partition "settings" 0x10000000 "${BACKUP_DIR}/settings.ext4"
backup_partition "system_a" 0x2040B000 "${BACKUP_DIR}/system_a.ext2"
backup_partition "system_b" 0x2040B000 "${BACKUP_DIR}/system_b.ext2"


announce "Dumping partition: data"
# data partition size is either 0x889EA000 (4476752 sectors) or 0x859EA000 (4378448 sectors)
echo "Trying data partition size: 0x889EA000"
$UPDTOOL mread store data normal 0x889EA000 "${BACKUP_DIR}/data.ext4" || {
    echo "Trying other data partition size: 0x859EA000"
    $UPDTOOL mread store data normal 0x859EA000 "${BACKUP_DIR}/data.ext4" || {
        echo "Failed to backup data partition at either of known sizes: 0x889EA000, 0x859EA000"
        echo "Backup incomplete!"
        bail
    }
}


announce "Calculating checksums"
pushd "${BACKUP_DIR}" || bail
md5sum ./* >checksums.txt
popd || bail

announce "Finished Creating Backup: in ${BACKUP_DIR}, please note that it is owned by root!"
