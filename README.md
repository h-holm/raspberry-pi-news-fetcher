### Repo for running Calibre on my Raspberry Pi to fetch news as epubs and sync the fetched news to my Kobo e-reader over Dropbox.

More precisely, the `ebook-convert` command in the Calibre CLI is used to fetch news. Since Calibre cannot be installed on Raspbian as of writing (2022-02-02), I set up Calibre on a Docker container running on my Raspberry Pi. I schedule the container to run the `scripts/run_recipes.sh` script (which runs `ebook-convert`) weekly by setting it up on a K3s CronJob (K3s is a small K8s install capable of running on a Raspberry Pi).

For the Dropbox syncing, I use `rclone` and `rclonesync`. New news epubs are added to the synced Dropbox folder. News older than 2 weeks are removed.

#### Dockerfile

A raspberrypi3-debian-based image with `Calibre` installed. As of 2022-02-02, no Raspbian-compatible version of `Calibre` exists. Thus, running `Calibre` on a Docker container on your Raspberry Pi is a convenient workaround.

#### fetch-news-k8s-cron-job.yml

K8s CronJob running scripts/run_recipes.sh in the Calibre-compatible Docker container every Friday at 6 A.M.

#### /scripts

`install.sh` - `rclone` installation script.

`run_rclonesync.sh` - script for syncing a remote Dropbox folder with a local directory. Perfect for a cronjob.

`run_recipes.sh` - script for running `ebook-convert` to fetch news and store them as epubs in the /fetched-news folder.

#### /instructions

This folder contains instruction files for
- building a Docker image with Calibre installed which can run as a container on my Raspberry Pi;
- installing `K3s` on Raspbian;
- setting up a K8s CronJob using `K3s` which runs the news-fetching script inside the Docker container with `Calibre` installed;
- setting up `rclone` and `rclonesync`

#### /fetched-news

Fetched news epubs show up here.

#### /logs

Logs show up here.