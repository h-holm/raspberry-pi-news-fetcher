# Raspberry Pi News Fetcher

[Instructions](./instructions), [Bash scripts](./scripts), a [Dockerfile](Dockerfile) and a [K8s CronJob manifest](./news_fetcher_k8s_cronjob.yml) for configuring a Raspberry Pi to fetch news at regular intervals and sync the resulting EPUBs to [Dropbox](https://www.dropbox.com).

- News from [sources](./SOURCES) such as [The Economist](https://www.economist.com) are scraped and parsed into EPUB files using the `ebook-convert` command of the [Calibre command-line interface](https://manual.calibre-ebook.com/generated/en/cli-index.html).
- The news scraping is configured to run at regular intervals via a [K8s CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs).
- EPUB files are synced to a Dropbox remote using [rclone](https://rclone.org). By having the same Dropbox folder configured on an e-reader device (in my case a [Kobo Libra H2O](https://help.kobo.com/hc/en-us/articles/360032442774-Kobo-Libra-H2O)), scraped news are automatically synced directly to your hands (and eyes).

The sources to fetch news from are defined in the one-source-per-line [SOURCES](SOURCES) file. Refer to the [Calibre GitHub repo](https://github.com/kovidgoyal/calibre/tree/master/recipes) for a list of available scraping *recipes*. You can also [write your own Calibre news recipe](https://manual.calibre-ebook.com/news_recipe.html).

## Raison d'Être

My 32-bit, [Raspbian Bullseye](https://www.raspberrypi.com/news/raspberry-pi-os-debian-bullseye)-based Raspberry Pi is incompatible with newer versions of Calibre due to `qtwebengine` not being supported on `armv7`:

```shell
$ sudo apt install calibre
[...]
The following packages have unmet dependencies:
 calibre : Depends: calibre-bin (>= 5.12.0+dfsg-1+deb11u3) but it is not installable
           Depends: python3-pyqt5.qtwebengine (>= 5.12.1-4+b1) but it is not installable
           Recommends: python3-dnspython (>= 1.6.0) but it is not going to be installed
E: Unable to correct problems, you have held broken packages.
```

For this reason, I instead build a container image and run the Calibre workload as a K8s CronJob on a [K3s](https://k3s.io) cluster set up on my Raspberry Pi. If you are able to directly install a suitable version of Calibre on your device, go ahead and forego the K8s CronJob set-up.

Exact Raspberry Pi specs:

<details>
  <summary>Click to (un-)collapse</summary>

```shell
$ cat /etc/os-release
PRETTY_NAME="Raspbian GNU/Linux 11 (bullseye)"
NAME="Raspbian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=raspbian
ID_LIKE=debian
HOME_URL="http://www.raspbian.org/"
SUPPORT_URL="http://www.raspbian.org/RaspbianForums"
BUG_REPORT_URL="http://www.raspbian.org/RaspbianBugs"
$ uname -m
armv7l
```

</details>

## Requirements

A Raspberry Pi device with some flavor of Kubernetes installed. See [./instructions/2-install-k3s.md](./instructions/2-install-k3s.md) for an example of how to configure [K3s](https://k3s.io) on Raspberry Pi.

## Summary

- The [Kubernetes CronJob](news_fetcher_k8s_cronjob.yml) scrapes news by running the [./scripts/fetch_news.sh](./scripts/fetch_news.sh) script, which executes the Calibre CLI `ebook-convert` command. EPUB files are by default output to the [./fetched-news](./fetched-news) directory and logs to [./logs](./logs).

- Two "regular" Linux cron jobs on the Raspberry Pi manage the following housekeeping tasks:

    1. [./scripts/housekeep_news.sh](./scripts/housekeep_news.sh):
       - copy new EPUB files from [./fetched-news](./fetched-news) to the local clone of the Dropbox folder,
       - delete EPUB files older than `--max-num-days`.

    2. [./scripts/run_rclone_bisync.sh](./scripts/run_rclone_bisync.sh):
        - sync the local Dropbox folder with its cloud remote using `rclone bisync` (bidirectional to ensure that the deletion of old files from the local Dropbox folder is mirrored on the remote).

  Similar to the K8s CronJob, the above Linux cron jobs by default output logs to the [./logs](./logs) directory.

## [Dockerfile](Dockerfile)

A [`raspberrypi3-debian`](https://hub.docker.com/r/balenalib/raspberrypi3-debian)-based image with the `calibre` command-line tool installed. Feel free to use the [Docker image I build and maintain](https://hub.docker.com/repository/docker/henholm/raspberry-pi-news-fetcher), in which case you can disregard this file.

## The [./instructions](./instructions) directory

Contains instructions outlining the steps to get the set-up up and running. Go through the instructions in the following order:

1. [./instructions/1-build-docker-image.md](./instructions/1-build-docker-image.md): building a Docker image with the `calibre` command-line tool installed,

2. [./instructions/2-install-k3s.md](./instructions/2-install-k3s.md): setting up [K3s](https://k3s.io/) on Raspberry Pi OS,

3. [./instructions/3-set-up-rclone.md](./instructions/3-set-up-rclone.md): configuring [`rclone`](https://rclone.org),

4. [./instructions/4-set-up-cronjobs.md](./instructions/4-set-up-cronjobs.md): defining Linux housekeeping cron jobs,

5. [./instructions/5-set-up-k8s-cronjob.md](./instructions/5-set-up-k8s-cronjob.md): configuring the K8s CronJob.

## The [./scripts](./scripts) directory

Contains the three Bash scripts that perform the (1) news-fetching, (2) housekeeping and (3) cloud-storage syncing.

## [news_fetcher_k8s_cronjob.yml](news_fetcher_k8s_cronjob.yml)

Kubernetes CronJob for running [./scripts/fetch_news.sh](./scripts/fetch_news.sh) at a scheduled interval in a container based on the Calibre-compatible container image defined by the [Dockerfile](Dockerfile).

## [./recipes](./recipes)

If you wish to use local Calibre `.recipe` files, they should be put here. The [./scripts/fetch_news.sh](./scripts/fetch_news.sh) checks whether a recipe exists locally. If that is the case, the local recipe takes precedence over Calibre's built-in recipe. If a source specified in the [SOURCES](SOURCES) file exists neither as a local recipe in the [./recipes](./recipes) directory nor among Calibre's built-in recipes, the [./scripts/fetch_news.sh](./scripts/fetch_news.sh) script will skip that source.

## [./fetched-news](./fetched-news)

By default, fetched news EPUBs show up here.

## [./logs](./logs)

By default, logs show up here.

## [./.github/workflows/build-and-push-image.yml](./.github/workflows/build-and-push-image.yml)

A [GitHub Actions](https://docs.github.com/en/actions) CI workflow config for automatically building and pushing a container image on push to the `main` branch.
