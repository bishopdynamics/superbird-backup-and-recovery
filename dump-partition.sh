#!/bin/bash
# create a full backup of one partition


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

PART_NAME="$1"
OUTFILE="$2"

if [ -z "$PART_NAME" ] || [ -z "$OUTFILE" ]; then
    echo "missing a required parameter. usage: ./backup-partition.sh <partition-name> <output-file>"
    exit 1
fi

DIR=$(dirname "$(realpath "$0")")
UPDTOOL="${DIR}/amlogic-usb-tool"

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

if [ "$PART_NAME" == "bootloader" ]; then
    PART_SIZE="0x200000"
elif [ "$PART_NAME" == "env" ]; then
    PART_SIZE="0x800000"
elif [ "$PART_NAME" == "fip_a" ]; then
    PART_SIZE="0x400000"
elif [ "$PART_NAME" == "fip_b" ]; then
    PART_SIZE="0x400000"
elif [ "$PART_NAME" == "logo" ]; then
    PART_SIZE="0x800000"
elif [ "$PART_NAME" == "dtbo_a" ]; then
    PART_SIZE="0x400000"
elif [ "$PART_NAME" == "dtbo_b" ]; then
    PART_SIZE="0x400000"
elif [ "$PART_NAME" == "vbmeta_a" ]; then
    PART_SIZE="0x100000"
elif [ "$PART_NAME" == "vbmeta_b" ]; then
    PART_SIZE="0x100000"
elif [ "$PART_NAME" == "boot_a" ]; then
    PART_SIZE="0x1000000"
elif [ "$PART_NAME" == "boot_b" ]; then
    PART_SIZE="0x1000000"
elif [ "$PART_NAME" == "misc" ]; then
    PART_SIZE="0x800000"
elif [ "$PART_NAME" == "settings" ]; then
    PART_SIZE="0x10000000"
elif [ "$PART_NAME" == "system_a" ]; then
    PART_SIZE="0x2040B000"
elif [ "$PART_NAME" == "system_b" ]; then
    PART_SIZE="0x2040B000"
elif [ "$PART_NAME" == "data" ]; then
    PART_SIZE="0x889EA000"
else
    echo "unknown partition: $PART_NAME"
    exit
fi


# initialize mmc subsystem
$UPDTOOL bulkcmd "amlmmc part 1"


# handle two possible sizes for data partition
if [ "$PART_NAME" == "data" ]; then
    announce "Dumping partition: data"
    # data partition size is either 0x889EA000 (4476752 sectors) or 0x859EA000 (4378448 sectors)
    echo "Trying data partition size: 0x889EA000"
    backup_partition "$PART_NAME" "$PART_SIZE" "$OUTFILE" || {
        echo "Trying other data partition size: 0x859EA000"
        PART_SIZE="0x859EA000"
        backup_partition "$PART_NAME" "$PART_SIZE" "$OUTFILE" || {
            echo "Failed to backup data partition at either of known sizes: 0x889EA000, 0x859EA000"
            echo "Backup incomplete!"
            bail
        }
    }
else
    backup_partition "$PART_NAME" "$PART_SIZE" "$OUTFILE"
fi
