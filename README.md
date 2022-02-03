### Repo for running Calibre on my Raspberry Pi to fetch news as epubs and sync the fetched news to my Kobo e-reader over Dropbox.

#### Summary

- The `ebook-convert` command in the Calibre CLI is used to fetch news.
- Since Calibre cannot be installed on Raspbian as of writing (2022-02-02) due to dependency issues, Calibre is instead set up on a Docker container.
- The Docker container is hooked up as a K3s CronJob (K3s is a small K8s install suitable for Raspberry Pis).
- The K3s CronJob executes the `scripts/run_recipes.sh` script (which runs `ebook-convert` to fetch news) weekly, meaning that news are downloaded and converted to epubs once a week.
- Two "regular" cronjobs are set up locally on the Raspberry Pi (as opposed to on a K3s cluster):
- 1. One to manage (a) the `fetched-news` folder where downloaded epubs are stored, and (b) the Dropbox folder which is synced with the cloud. With "managing", I here refer to automatically moving files between the folders as well as deleting files older than > `max_age`.
- 2. One to run the syncing of the local Dropbox folder with its cloud remote. The utils `rclone` and `rclonesync` are used for this purpose.
- Currently, four news sources are considered. That said, adding or removing sources is a matter of adding/removing strings from an array.

#### Dockerfile

A raspberrypi3-debian-based image with `Calibre` installed. As mentioned above, no Raspbian-compatible version of `Calibre` exists as of 2022-02-02. Thus, running `Calibre` on a Docker container on your Raspberry Pi is a convenient workaround.

#### fetch-news-k8s-cron-job.yml

K8s CronJob running `scripts/run_recipes.sh` in the Calibre-compatible Docker container every Friday at 6 A.M.

#### /scripts

`install.sh` - `rclone` installation script.

`run_rclonesync.sh` - script for syncing a remote Dropbox folder with a local directory. Ideal for running as a cronjob.

`run_recipes.sh` - script for running `ebook-convert` to fetch news and store them as epubs in the /fetched-news folder.

`update_news.sh` - script for automatically removing old epubs from both the `/fetched-news` and the local Dropbox folder, as well as moving newly fetched news epubs from `/fetched-news` to the Dropbox folder.

#### /instructions

This folder contains instruction files for
- building a Docker image with Calibre installed which can run as a container on your Raspberry Pi;
- creating a backup image of your Raspberry Pi on MacOS;
- installing `K3s` on Raspbian;
- setting up cronjobs on your Raspberry Pi;
- setting up a K8s CronJob using `K3s` which runs the news-fetching script inside the Docker container with `Calibre` installed;
- setting up `rclone` and `rclonesync`.

#### /fetched-news

Fetched news epubs show up here.

#### /logs

Logs show up here.