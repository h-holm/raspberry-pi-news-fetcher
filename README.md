# Raspberry Pi News Fetcher

[Bash scripts](./scripts) and steps for configuring a Raspberry Pi to:

- scrape news into EPUBs using [Calibre's `ebook-convert`](https://manual.calibre-ebook.com/generated/en/cli-index.html) command,
- sync EPUBs to a [Dropbox](https://www.dropbox.com) folder via [`rclone`](https://rclone.org),
- perform housekeeping tasks such as deleting EPUBs older than `--max-num-days`,
- configuring the above steps to run recurringly as cron jobs.

The set-up should work on any Unix/Linux machine supporting cron jobs, `rclone` and a decently recent version of Calibre.

By having the same Dropbox folder configured on an e-reader device (in my case a [Kobo Libra H2O](https://help.kobo.com/hc/en-us/articles/360032442774-Kobo-Libra-H2O)), scraped news are automatically synced directly to your hands and eyes.

## 1. Requirements

Decently recent versions of:

- Calibre,
- `rclone`,
- Bash.

My 8GB Raspberry Pi 4 Model B has the following specs and package versions:

```shell
$ uname -a
Linux raspberrypi 6.6.31+rpt-rpi-v8 #1 SMP PREEMPT Debian 1:6.6.31-1+rpt1 (2024-05-29) aarch64 GNU/Linux
$ calibre --version
calibre (calibre 6.13)
$ rclone --version
rclone v1.68.0
- os/version: raspbian 12.7 (64 bit)
- os/kernel: 6.6.31+rpt-rpi-v8 (aarch64)
- os/type: linux
- os/arch: arm64 (ARMv8 compatible)
- go/version: go1.23.1
- go/linking: static
- go/tags: none
$ bash --version
GNU bash, version 5.2.15(1)-release (aarch64-unknown-linux-gnu)
```

### 1.1 Calibre Set-Up

```shell
sudo apt-get update && sudo apt-get upgrade && sudo apt-get install calibre
```

### 1.2 `rclone` Set-Up

`rclone` was installed and configured using the steps outlined in [rclone-setup.md](rclone-setup.md). Note that `rclone` should be configured to sync *bidirectionally* to ensure that the deletion of old files from the local Dropbox folder is mirrored on the remote.

### 1.3 Ensure Scripts Are Executable

```shell
chmod u+x scripts/*.sh
```

## 2. Structure

```text
.
├── README.md
├── SOURCES                   # A line-by-line text file of news sources to scrape.
├── rclone-setup.md           # Guide on configuring `rclone` to sync a local directory with a remote Dropbox folder.
├── recipes                   # If you wish to use local Calibre `.recipe` files, they should be put here.
└── scripts
    ├── fetch_news.sh         # A script that uses Calibre's `ebook-convert` command to scrape news into EPUBs.
    ├── housekeep_news.sh     # A script that copies EPUBs from one directory to another, and deletes EPUBs older than `--max-num-days`.
    └── run_rclone_bisync.sh  # A script that uses `rclone` to sync a local directory with a remote Dropbox folder.
```

The [./scripts/fetch_news.sh](./scripts/fetch_news.sh) checks whether a recipe exists locally. If that is the case, the local recipe takes precedence over Calibre's built-in recipe. If a source specified in the [SOURCES](SOURCES) file exists neither as a local recipe in the [./recipes](./recipes) directory nor among Calibre's built-in recipes, the [./scripts/fetch_news.sh](./scripts/fetch_news.sh) script skips that source. Refer to the [Calibre GitHub repo](https://github.com/kovidgoyal/calibre/tree/master/recipes) for a list of available scraping *recipes*. You can also [write your own Calibre news recipe](https://manual.calibre-ebook.com/news_recipe.html).

## 3. Example Crontab

```text
# Run the Calibre news scraping every Friday at 09:00.
0 9 * * 5 /PATH/TO/REPO/fetch_news.sh --sources-file /PATH/TO/REPO/SOURCES --output-dir /PATH/TO/FETCHED-NEWS >> /PATH/TO/REPO/logs/fetch_news.out 2>&1
# Run the housekeeping every 30 minutes.
*/30 * * * * /PATH/TO/REPO/scripts/housekeep_news.sh --sources-file /PATH/TO/REPO/SOURCES --from-dir /PATH/TO/FETCHED-NEWS --target-dir /PATH/TO/LOCAL_DROPBOX_DIR --max-num-days 6 >> /PATH/TO/REPO/logs/housekeep_news.out 2>&1
# Run the `rclone` syncing every 30 minutes.
*/30 * * * * /PATH/TO/REPO/scripts/run_rclone_bisync.sh --local-dropbox-dir /PATH/TO/LOCAL_DROPBOX_DIR --remote-name "REMOTE_NAME" --remote-dropbox-dir "REMOTE_DIR" >> /PATH/TO/REPO/logs/run_rclone_bisync.out 2>&1
```

## 4. Scheduling the Scraping Using a Kubernetes (K8s) CronJob

In the past, I was unable to install Calibre directly on my Raspberry Pi due to it being incompatible with newer versions of Calibre. For this reason, I set up a [K3s](https://k3s.io) cluster on my Raspberry Pi, built a container image with Calibre installed, and configured a [K8s CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs) to run the Calibre-based news-scraping workload. See the [`k8s-cronjob` branch](https://github.com/h-holm/raspberry-pi-news-fetcher/tree/k8s-cronjob) for more info.
