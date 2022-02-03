### 1. `scripts/run_rclonesync.sh`

I set the `scripts/run_rclonesync.sh` script to run as a cronjob every fourth hour starting at 00:00:

`0 0,4,8,12,16,20 * * * bash /home/pi/devel/rpi-books/scripts/run_rclonesync.sh >> /home/pi/devel/rpi-books/logs/run_rclonesync.out 2>&1`

### 2. `scripts/update-news.sh`

I set the `scripts/update-news.sh` script to run as a cronjob every fourth hour starting at 02:00:

`0 2,6,10,14,18,22 * * * bash /home/pi/devel/rpi-books/scripts/update-news.sh >> /home/pi/devel/rpi-books/logs/update-news.out 2>&1`