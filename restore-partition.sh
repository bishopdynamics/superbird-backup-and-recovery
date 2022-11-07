#!/bin/bash
# restore a single partition of superbird device


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

PART_NAME="$1"
DUMP_FILE="$2"

$UPDTOOL bulkcmd "amlmmc part 1"
$UPDTOOL mwrite "$DUMP_FILE" store "$PART_NAME" normal

echo "done restoring partition: $PART_NAME"
