# rpi-news-fetcher

Schedule cron jobs to fetch news from news sources specified in `SOURCES` using [Calibre](https://calibre-ebook.com/about). Sync the resulting `epub`s to a Dropbox folder. By having the same Dropbox folder configured on an e-reader device, such as my [Kobo](https://help.kobo.com/hc/en-us/articles/360032442774-Kobo-Libra-H2O), scraped news are automatically synced directly to your hands (and eyes).

## Summary

- Since newer versions of [Calibre](https://calibre-ebook.com/about) are not compatible with Raspberry Pi OS as of writing (2022-11-03) due to dependency issues, this repo instead installs the [`calibre` command-line interface (CLI)](https://manual.calibre-ebook.com/generated/en/cli-index.html) in a Docker image.
- The minimal Docker container is run as a Kubernetes `CronJob` on a [K3s](https://k3s.io/) cluster configured on the Raspberry Pi device.
- The Kubernetes `CronJob` mounts the `./fetched-news` directory and executes the `calibre` CLI `ebook-convert` command to scrape news, outputting resulting `epub`s to the `./fetched-news` directory.
- Two "regular" cron jobs on the Raspberry Pi manage the following housekeeping tasks:
    1. Housekeeping the `./fetched-news` directory and the local version of the Dropbox folder to sync with, i.e., copying new news `epub`s from `./fetched-news` to the Dropbox folder and deleting news `epub`s older than `max_num_days`.
    2. Syncing the local Dropbox folder with its cloud remote using `rclone` and `rclonesync` (for bidirectional syncing so that the deletion of old files from the local Dropbox folder is mirrored on the remote).

## `Dockerfile`

A [`raspberrypi3-debian`](https://hub.docker.com/r/balenalib/raspberrypi3-debian)-based image with the `calibre` command-line tool installed.

## `./instructions/`

This directory contains instructions outlining the necessary steps to get the setup up and running. It is recommended to go through the instructions in the following order:
1. `./instructions/1-build-docker-image.md`: building a Docker image with the `calibre` command-line tool installed,
2. `./instructions/2-install-k3s-on-raspbian.md`: installing `K3s` on Raspberry Pi OS,
3. `./instructions/3-set-up-rclone.md`: setting up `rclone` and `rclonesync`,
4. `./instructions/4-set-up-cronjobs.md`: setting up cron jobs,
5. `./instructions/5-set-up-cronjobs.md`: setting up a Kubernetes `CronJob` on a `K3s` cluster which runs the `./scripts/fetch_news.sh` script inside a Docker container with `Calibre` installed.

## `./scripts/`

- `./scripts/install.sh`: `rclone` installation script to be executed once.
- `./scripts/fetch_news.sh`: script to be scheduled as a cron job for running `ebook-convert` to fetch news and store them as `epub`s in the `./fetched-news/` directory.
- `./scripts/housekeep_news.sh`: script to be scheduled as a cron job for removing old `epub`s from both `./fetched-news/` and the local Dropbox folder, as well as for moving newly fetched news `epub`s from `./fetched-news/` to the local Dropbox folder.
- `./scripts/run_rclonesync.sh`: script to be scheduled as a cron job for syncing a local Dropbox folder with a remote Dropbox folder.

## `fetch_news_k8s_cronjob.yml`

Kubernetes `CronJob` running `./scripts/fetch_news.sh` in the `calibre`-compatible Docker container at the scheduled interval.

## `./fetched-news/`

Fetched news `epub`s show up here.

## `./logs/`

Logs show up here.