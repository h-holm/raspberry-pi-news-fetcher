# 3-set-up-rclone.md

This file provides instructions for installing and setting up [`rclone`](https://rclone.org), which can be used to sync a local directory with a remote Dropbox folder (or any other remote cloud storage that `rclone` supports).

From the [rclone docs](https://rclone.org):

> Rclone is a command-line program to manage files on cloud storage. It is a feature-rich alternative to cloud vendors' web storage interfaces. 

The below steps draw inspiration from:
- https://howchoo.com/pi/how-to-install-dropbox-on-a-raspberry-pi

## 1. Update your Raspberry Pi

```shell
$ sudo apt update && sudo apt upgrade
```

## 2. Download the `rclone` install script

Download the `rclone` installation script directly from [rclone.org](https://rclone.org/install.sh) instead of using `apt` (the `rclone` version available on the Raspbian and Raspberry Pi OS repository is usually old):

```shell
$ wget https://rclone.org/install.sh -O scripts/rclone_install.sh
```

## 3. Run the install script

```shell
$ sudo bash ./scripts/rclone_install.sh
```

## 4. Configure `rclone`

After having been installed, it is time to configure `rclone`. The [above link](https://howchoo.com/pi/how-to-install-dropbox-on-a-raspberry-pi) provides instructions for performing this step on a headless set-up. As I had [VNC Viewer](https://www.realvnc.com/en/connect/download/viewer) installed, however, I used it to get a screen view of my Raspberry Pi for this step. Either way, the config process is straightforward. It is started by running the following command:

```shell
$ rclone config
```

## 5. Set environment variables

To avoid having to type in the same string multiple times, set environment variables for the remote you set up, as well as the specific folder on the remote that you wish to sync with, e.g.:

```shell
$ export REMOTE_NAME=DROPBOX
$ export REMOTE_FOLDER=NEWS
```

## 6. Create a local Dropbox folder

Configure a local directory to use as the local version of your Dropbox folder:

```shell
$ export LOCAL_FOLDER=$HOME/dropbox-news
$ mkdir $LOCAL_FOLDER
```

## 7. Run initial sync of remote and local

Copy down all the contents of the remote folder to the local folder for an initial setup:

```shell
$ rclone copy $REMOTE_NAME:/$REMOTE_FOLDER $LOCAL_FOLDER
```

## 8. Run initial bidirectional sync

The first time bidirectionally syncing the local and the remote, run `rclone bisync` with the `--resync` flag.

```shell
$ rclone bisync --resync --verbose $LOCAL_FOLDER $REMOTE_NAME:/$REMOTE_FOLDER
```

## 9. Leave out `--resync` for successive sync runs

Now, you can run the following command whenever you wish to bidirectionally sync your folders (for instance using a cron job):

```shell
$ rclone bisync --verbose $LOCAL_FOLDER $REMOTE_NAME:/$REMOTE_FOLDER
```