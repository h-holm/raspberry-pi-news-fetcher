# raspberry-pi-news-fetcher

This repo contains [instructions](./instructions), [bash scripts](./scripts), a [Dockerfile](Dockerfile) and a [K8s CronJob config](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) that together can be used to set up a Raspberry Pi to fetch news at regular intervals using [Calibre](https://calibre-ebook.com/about) (or rather, the [Calibre command-line interface](https://manual.calibre-ebook.com/generated/en/cli-index.html)).

The sources to fetch news from, using [Calibre's](https://calibre-ebook.com/about) `ebook-convert` command, are defined in the one-news-source-per-line [SOURCES](SOURCES) file. Refer to the [Calibre GitHub repo](https://github.com/kovidgoyal/calibre/tree/master/recipes) for a list of available *recipes* (Calibre refers to news-fetching scripts as "recipes"). You can also [write your own Calibre news recipe](https://manual.calibre-ebook.com/news_recipe.html).

The `epub` files output by the `ebook-convert` scraping are synced to a [Dropbox](https://www.dropbox.com) folder using [`rclone`](https://rclone.org). By having the same Dropbox folder configured on an e-reader device (in my case by setting up [KoboCloud](https://github.com/fsantini/KoboCloud) on my [Kobo Libra H2O](https://help.kobo.com/hc/en-us/articles/360032442774-Kobo-Libra-H2O)), scraped news are automatically synced directly to your hands (and eyes).

## Requirements

A Raspberry Pi device, and, if you want to build and use your own Docker image(s), a [Docker Hub account](https://hub.docker.com/signup) or some other registry you can push Docker images to. Alternatively, feel free to use the [Docker image I build and maintain](https://hub.docker.com/repository/docker/henholm/raspberry-pi-news-fetcher).

## Summary

- As newer versions of [Calibre](https://calibre-ebook.com/about) are incompatible with most Raspberry Pi OS:es due to `qtwebengine` not being supported on `armv6`, this repo instead installs the [`calibre` command-line interface (CLI)](https://manual.calibre-ebook.com/generated/en/cli-index.html) in a Docker image.
- The minimal Docker container is run as a Kubernetes `CronJob` on a [K3s](https://k3s.io/) cluster configured on the Raspberry Pi device. (To forego the K3s CronJob and use a regular cron job instead, you can of course install a Raspberry Pi OS compatible with Calibre.)
- The [Kubernetes `CronJob`](fetch_news_k8s_cronjob.yml) executes the Calibre CLI `ebook-convert` command to scrape news (by running the [./scripts/fetch_news.sh](./scripts/fetch_news.sh) script), outputting resulting `epub` files to the [./fetched-news](./fetched-news) directory and logs to [./logs](./logs).
- Two "regular" cron jobs on the Raspberry Pi manage the following housekeeping tasks:

    1. Housekeeping the [./fetched-news](./fetched-news) directory and the local version of the Dropbox folder to sync with, i.e., (I) copying new `epub` files from [./fetched-news](./fetched-news) to the local Dropbox folder, and (II) deleting `epub` files older than `max_num_days`.

    2. Syncing the local Dropbox folder with its cloud remote using `rclone bisync` (bidirectional syncing to ensure that the deletion of old files from the local Dropbox folder is mirrored on the remote).

  These two cron jobs run the [./scripts/housekeep_news.sh](./scripts/housekeep_news.sh) and [./scripts/run_rclone_bisync.sh](./scripts/run_rclone_bisync.sh) scripts, respectively, and, similar to the [K8s `CronJob`](fetch_news_k8s_cronjob.yml), output logs to the [./logs](./logs) directory.

## [Dockerfile](Dockerfile)

A [`raspberrypi3-debian`](https://hub.docker.com/r/balenalib/raspberrypi3-debian)-based image with the `calibre` command-line tool installed. Feel free to use the [Docker image I build and maintain](https://hub.docker.com/repository/docker/henholm/raspberry-pi-news-fetcher), in which case you can disregard this file.

## The [./instructions](./instructions) directory

This directory contains instructions outlining the necessary steps to get the setup up and running. It is recommended to go through the instructions in the following order:

1. [./instructions/1-build-docker-image.md](./instructions/1-build-docker-image.md): building a Docker image with the `calibre` command-line tool installed,

2. [./instructions/2-install-k3s.md](./instructions/2-install-k3s.md): installing [K3s](https://k3s.io/) on Raspberry Pi OS,

3. [./instructions/3-set-up-rclone.md](./instructions/3-set-up-rclone.md): installing and configuring [`rclone`](https://rclone.org),

4. [./instructions/4-set-up-cronjobs.md](./instructions/4-set-up-cronjobs.md): setting up cron jobs,

5. [./instructions/5-set-up-k8s-cronjob.md](./instructions/5-set-up-k8s-cronjob.md): setting up a Kubernetes `CronJob` on a `K3s` cluster which runs the [./scripts/fetch_news.sh](./scripts/fetch_news.sh) script inside a Docker container with `Calibre` installed.

## The [./scripts](./scripts) directory

This directory contains three bash scripts that we run as cron jobs to regularly execute the necessary tasks of (1) news-fetching, (2) housekeeping and (3) cloud-storage syncing.

- [./scripts/fetch_news.sh](./scripts/fetch_news.sh): runs `ebook-convert` to fetch news and store them as `epub` files in the [./fetched-news](./fetched-news) directory (to be executed by a K8s `CronJob`).

- [./scripts/housekeep_news.sh](./scripts/housekeep_news.sh): (1) moves new news `epub` files from [./fetched-news](./fetched-news) to the local Dropbox folder, and (2) removes old `epub` files from *both* [./fetched-news](./fetched-news) and the local Dropbox folder (to be scheduled as a cron job).

- [./scripts/run_rclone_bisync.sh](./scripts/run_rclone_bisync.sh): syncs a local Dropbox folder with a remote Dropbox folder bidirectionally (to be scheduled as a cron job).

## [fetch_news_k8s_cronjob.yml](fetch_news_k8s_cronjob.yml)

Kubernetes `CronJob` config for running [./scripts/fetch_news.sh](./scripts/fetch_news.sh) at the scheduled interval in a container based on the `calibre`-compatible Docker image defined in [Dockerfile](Dockerfile).

## [./recipes](./recipes)

If you wish to use local `.recipe` files, they should be put here. The [./scripts/fetch_news.sh](./scripts/fetch_news.sh) checks whether a recipe exists locally. If that is the case, the local recipe takes precedence over Calibre's built-in recipe. If a source specified in the [SOURCES](SOURCES) file exists neither as a local recipe in the [./recipes](./recipes) directory nor among Calibre's built-in recipes, the [./scripts/fetch_news.sh](./scripts/fetch_news.sh) script will skip that source.

## [./fetched-news](./fetched-news)

Fetched news `epub` files show up here.

## [./logs](./logs)

Logs show up here.

## [./.github/workflows/ci.yml](./.github/workflows/ci.yml)

A [GitHub Actions](https://docs.github.com/en/actions) CI config file for automatically building and pushing a Docker image from the [Dockerfile](Dockerfile) on push to or merge into the `main` branch.

Note that you can disregard setting up CI and instead "manually" build a Docker image if you wish to (guidance for doing so can be found in [./instructions/1-build-docker-image.md](./instructions/1-build-docker-image.md)).

Note also that you can directly use the [Docker image I build and maintain](https://hub.docker.com/repository/docker/henholm/raspberry-pi-news-fetcher), in which case you can disregard both the CI and the [./instructions/1-build-docker-image.md](./instructions/1-build-docker-image.md) step.