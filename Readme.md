# Superbird (Spotify Car Thing) Backup & Recovery

This is just a re-packaging of [frederic's work](https://github.com/frederic/superbird-bulkcmd)
with lots more comments and added restore scripts.

I created this to make it easier for me to rapidy backup & restore my device, while experimenting with 
implementing the same behavior in [`superbird-tool`](https://github.com/bishopdynamics/superbird-tool)

This ONLY works on Linux x86_64

## Script: `dump-device.sh`

Dump all partitions from a device connected in USB Burn mode, then calculates checksums.

Creates backups in folder `dumps/`, which is gitignored.

With no argument, folder name will be `dump-$(date "+%Y%m%d_%H%M%S")`, 
if you pass an argument instead: `custom-${1}-$(date "+%Y%m%d_%H%M%S")`

Example: `./dump-device.sh "dev-chroot"` will result in `dumps/custom-dev-chroot-20221023_190543`

## Script: `dump-partition.sh`

Dump a single given partition to a file.

Example: `./dump-partition.sh bootloader bootloader.dump`

## Script: `restore-device.sh`

Restore all partitions, given a backup folder made by `dump-device.sh`

Example: `./restore-device.sh dumps/custom-dev-chroot-20221023_190543`

## Script `restore-partition.sh`

Restore a given partition from a file.

Example: `./restore-partition.sh bootloader dumps/custom-dev-chroot-20221023_190543/bootloader.dump`