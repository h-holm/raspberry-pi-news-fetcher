# 4-set-up-cronjobs.md

## 1. Ensure the necessary scripts are executable

```shell
$ chmod u+x scripts/*.sh
```

## 2. Set up `rclone bisync` cron job

Set the [scripts/run_rclone_bisync.sh](../scripts/run_rclone_bisync.sh) script to run at regular intervals, ensuring that the local and remote Dropbox folders stay in sync. In my case, I `crontab -e` and set the script to run every fourth hour starting at 00:00:

```shell
$ crontab -e
...
0 0,4,8,12,16,20 * * * /PATH/TO/THIS/REPO/scripts/run_rclone_bisync.sh --local-dropbox-dir /PATH/TO/LOCAL/DROPBOX-DIR --remote-name REMOTE-DROPBOX-NAME --remote-dropbox-dir REMOTE-DROPBOX-DIR >> /PATH/TO/THIS/REPO/logs/run_rclone_bisync.out 2>&1
```

## 2. Set up 'housekeeping' cron job

Set the [scripts/housekeep_news.sh](../scripts/housekeep_news.sh) script to run at regular intervals, ensuring that (1) fetched news `epub` files are copied from the [fetched-news](../fetched-news) directory to the local Dropbox folder, and (2) old scraped `epub` files are removed after exceeding the specified age. In my case, I `crontab -e` and set the script to run every fourth hour starting at 02:00:  

```shell
$ crontab -e
...
0 2,6,10,14,18,22 * * * /PATH/TO/THIS/REPO/scripts/housekeep_news.sh --sources-file /PATH/TO/THIS/REPO/SOURCES --from-dir /PATH/TO/THIS/REPO/fetched-news --target-dir /PATH/TO/LOCAL/DROPBOX-DIR --max-num-days 14 >> /PATH/TO/THIS/REPO/logs/housekeep_news.out 2>&1
```