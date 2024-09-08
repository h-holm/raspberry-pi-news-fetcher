# `rclone` Set-Up

This document provides instructions for installing and setting up [`rclone`](https://rclone.org), which can be used to sync a local directory with a remote Dropbox folder (or any other remote cloud storage supported by `rclone`).

From the [rclone docs](https://rclone.org):

> Rclone is a command-line program to manage files on cloud storage. It is a feature-rich alternative to cloud vendors' web storage interfaces. 

The below steps draw inspiration from:
- https://howchoo.com/pi/how-to-install-dropbox-on-a-raspberry-pi

## 1. Update Your Raspberry Pi

Before installing `rclone`, it's a good idea to run an `apt upgrade`:

```shell
$ sudo apt update && sudo apt upgrade
```

## 2. Install `rclone`

Install `rclone` directly from [rclone.org](https://rclone.org/install.sh) instead of using `apt` (the `rclone` version available on the Raspbian and Raspberry Pi OS repositories is not always up-to-date):

```shell
$ sudo -v ; curl https://rclone.org/install.sh | sudo bash
```

## 3. Configure `rclone`

Different approaches to configuring `rclone` exist. Refer to the [rclone docs](https://rclone.org/dropbox) for an approach that suits you. To mention some of the options, you can configure `rclone` to access the remote you set up using your personal identity. In the case of Dropbox, you can also set up `rclone` to authenticate over a [Dropbox App](https://rclone.org/dropbox/#get-your-own-dropbox-app-id). Moreover, both headless and headful configuration processes are supported. For a headful approach on your Raspberry Pi, you can for instance look into [VNC Viewer](https://www.realvnc.com/en/connect/download/viewer). Again, this choice is up to you. Running the `rclone config` command by itself (i.e., without providing any flags) starts an interactive config process with informative help messages and instructions.

In the following sections, I document the **headless set-up process using a Dropbox App** that I performed.

### 3.1. Define Environment Variables

To avoid having to type the same strings multiple times, set environment variables for:

1. the type of remote you wish to set up,
2. the name you wish to give the remote,
3. the "App key" of your Dropbox App (which can be found in the "Settings" pane of your Dropbox App), and
4. the "App secret" of your Dropbox App (which can be found in the "Settings" pane of your Dropbox App).

For example:

```shell
$ export REMOTE_TYPE=dropbox
$ export REMOTE_NAME=my-dropbox
$ export APP_KEY=hash-copied-from-dropbox-app-settings
$ export APP_SECRET=hash-copied-from-dropbox-app-settings
```

### 3.2. Create `rclone` Config File

On a headful device (in my case, my laptop), run the below `rclone config` command to (1) confirm that the Dropbox App should be given the permissions listed in the web browser window linked to in the output of the `rclone config` command, and (2) create an entry in the `~/.config/rclone/rclone.conf` file for the Dropbox remote.

```shell
# On my MacBook:
$ rclone config create "$REMOTE_NAME" "$REMOTE_TYPE" --dropbox-client-id "$APP_KEY" --dropbox-client-secret "$APP_SECRET"
```

Head over to the resulting link to confirm that the Dropbox App is allowed to access your Dropbox.

If the above went smoothly, an entry will have been added to your `~/.config/rclone/rclone.conf` file. Show the config file, locate the entry, and copy it to your clipboard:

```shell
# Still on my MacBook:
$ rclone config show
```

Copy the relevant entry to your clipboard.

Now, paste the entry into the `~/.config/rclone/rclone.conf` file *on your Raspberry Pi*:

```shell
# On my Raspberry Pi:
$ nano ~/.config/rclone/rclone.conf
```

The required entry has now been added to your Raspberry Pi's `~/.config/rclone/rclone.conf` file.

### 3.3. Verify That Remote Has Been Set Up

Run the below command to check whether the remote has been added to `rclone`:

```shell
$ rclone listremotes
```

## 4. Sync a Local Folder With the Remote Dropbox Folder

With `rclone` installed and your remote configured, it is time to connect a local directory to the specific folder on your Dropbox that you wish to sync with.

To avoid having to type in the same strings multiple times, set (or reuse if [already set up](#31-define-environment-variables)) environment variables for:

1. the remote you set up,
2. the specific folder on the remote that you wish to sync with,
3. the local directory to use as the local version of your Dropbox folder.

For example:

```shell
$ export REMOTE_NAME=my-dropbox
$ export REMOTE_FOLDER=news
$ export LOCAL_FOLDER=$HOME/dropbox-news
```

### 4.1. Run Initial Sync of Remote and Local

Copy down all the contents of the remote folder to the local folder for an initial setup:

```shell
$ rclone copy "$REMOTE_NAME":/"$REMOTE_FOLDER" "$LOCAL_FOLDER"
```

Unless your `$REMOTE_FOLDER` was empty, its contents should now show up in your `$LOCAL_FOLDER`:

```shell
$ ls "$LOCAL_FOLDER"
```

### 4.2. Run Initial Bidirectional Sync

The first time bidirectionally syncing the local and the remote, run `rclone bisync` with the `--resync` flag.

```shell
$ rclone bisync --resync --verbose "$LOCAL_FOLDER" "$REMOTE_NAME":/"$REMOTE_FOLDER"
```

### 4.3. Leave Out `--resync` for Successive Sync Runs

Now, you can run the following command whenever you wish to bidirectionally sync your folders (for instance using a cron job):

```shell
$ rclone bisync --verbose "$LOCAL_FOLDER" "$REMOTE_NAME":/"$REMOTE_FOLDER"
```
