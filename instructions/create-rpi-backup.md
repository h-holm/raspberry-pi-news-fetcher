### 1. Use `diskutil list`to identify disk name of Raspberry Pi SD card.

`diskutil list`

### 2. Run `dd` with superuser privileges. In this case, I place the output file (`of`) on my LaCie external hard drive and name it with today's date.

`sudo dd bs=4m if=/dev/disk3 of=/Volumes/LaCie/raspberry-pi-backup/rpi4-20220115-backup.img`
