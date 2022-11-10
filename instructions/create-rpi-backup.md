# create-rpi-backup.md

To help me remember how I created a back-up of my Raspberry Pi, I note down the steps here.

## 1. Use `diskutil list` to identify disk name of Raspberry Pi SD card

```shell
$ diskutil list
```

In my case, the disk name was `/dev/disk3`.

## 2. Run `dd` with superuser privileges

In my case, I place the output file (`of`) on my LaCie external hard drive and name it with today's date.

```shell
$ sudo dd bs=4m if=/dev/disk3 of=/Volumes/LaCie/raspberry-pi-backup/rpi4-20221111.img
```
