# 4-set-up-cronjobs.md

1. `scripts/run_rclonesync.sh`  

    I set the `scripts/run_rclonesync.sh` script to run as a cron job every fourth hour starting at 00:00:  

    `0 0,4,8,12,16,20 * * * /home/pi/devel/rpi-news-fetcher/scripts/run_rclonesync.sh --local-dropbox-dir /home/pi/dropbox-books-henrik --remote-name dropbox-books-henrik --remote-dropbox-dir dropbox_books >> /home/pi/devel/rpi-news-fetcher/logs/run_rclonesync.out 2>&1`

2. `scripts/housekeep_news.sh`  

    I set the `scripts/housekeep_news.sh` script to run as a cron job every fourth hour starting at 02:00:  

    `0 2,6,10,14,18,22 * * * /home/pi/devel/rpi-news-fetcher/scripts/housekeep_news.sh --sources-file /home/pi/devel/rpi-news-fetcher/SOURCES --from-dir /home/pi/devel/rpi-news-fetcher/fetched-news --target-dir /home/pi/dropbox-books-henrik >> /home/pi/devel/rpi-news-fetcher/logs/housekeep_news.out 2>&1`