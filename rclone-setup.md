# `rclone` Set-Up

From the [rclone docs](https://rclone.org):

> Rclone is a command-line program to manage files on cloud storage. It is a feature-rich alternative to cloud vendors' web storage interfaces.

This document provides instructions for installing and configuring [`rclone`](https://rclone.org) to sync a local directory with a remote Dropbox folder. Refer to the [`rclone` docs](https://rclone.org/overview) for an overview of supported remotes.

The below steps draw inspiration from [this article](https://howchoo.com/pi/how-to-install-dropbox-on-a-raspberry-pi).

## 1. Update Your Raspberry Pi

Before installing `rclone`, it is a good idea to update the package index and upgrade installed packages:

```shell
sudo apt-get update && sudo apt-get upgrade
```

## 2. Install `rclone`

Refer to the [`rclone` installation guide](https://rclone.org/install) for up-to-date steps on installing `rclone`. Typically, it is recommended to install the binary directly instead of using a package manager such as `apt`:

```shell
sudo -v ; curl https://rclone.org/install.sh | sudo bash
```

## 3. Configure `rclone`

Different approaches to configuring `rclone` exist. Refer to the [rclone docs](https://rclone.org/dropbox) for an approach that suits you. One option is to configure `rclone` to access a remote using your personal identity. Another option in the case of Dropbox is to authenticate over a [Dropbox App](https://rclone.org/dropbox/#get-your-own-dropbox-app-id). Moreover, both headless and headful configuration processes are supported. For a headful approach on your Raspberry Pi, you can for instance look into [VNC Viewer](https://www.realvnc.com/en/connect/download/viewer). This choice is up to you. Running the `rclone config` command by itself (i.e., without providing any flags) starts an interactive config process with informative help messages and instructions.

In the following sections, I document the **headless set-up process with authentication via a Dropbox App** that I performed.

### 3.1 Define Environment Variables

To avoid having to type the same strings multiple times, set the below environment variables. Note that the values are examples that you can/should modify to your needs.

For example:

```shell
export REMOTE_TYPE="dropbox"              # The type of remote you wish to set up.
export REMOTE_NAME="my-dropbox"           # The name you wish to give the remote.
export REMOTE_FOLDER="news"               # The folder on the remote to sync with.
export LOCAL_FOLDER="$HOME/dropbox-news"  # The local dir to sync with the remote folder.
export APP_KEY="APP-KEY-VALUE"            # The "App key" of your Dropbox App.
export APP_SECRET="APP-SECRET-VALUE"      # The "App secret" of your Dropbox App.
```

Note that the app key and app secrets are found in the "Settings" pane of your Dropbox App.

### 3.2 Create Local Folder

Create the local news directory if it does not already exist:

```shell
mkdir -p "$LOCAL_FOLDER"
```

### 3.3 Identify Path to `rclone` Config File

To identify the path to the `rclone` config file, run `rclone config file`. The command might tell you that the configuration file does not yet exist:

```shell
$ rclone config file
Configuration file doesn't exist, but rclone will use this path:
/home/pi/.config/rclone/rclone.conf
```

Regardless of whether the config file exists already or not, note down the file path. It typically defaults to `~/.config/rclone/rclone.conf`, which is what will be used in the below steps.

### 3.4 Configure the `rclone` Config File

To correctly configure the config file on your Raspberry Pi, a headful device such as a laptop is helpful for the following two steps, as the `rclone config` command requires opening a URL in a web browser.

On a headful device, run:

```shell
# On my MacBook:
rclone config create "$REMOTE_NAME" "$REMOTE_TYPE" --dropbox-client-id "$APP_KEY" --dropbox-client-secret "$APP_SECRET"
```

Head over to the URL output by the command to confirm that the Dropbox App is allowed to access your Dropbox.

If the above went smoothly, an entry will have been added to the `~/.config/rclone/rclone.conf` file on your headful device. Show the config file, locate the newly-added entry, and copy it to your clipboard:

```shell
# Still on my MacBook:
rclone config show
```

With the relevant entry copied to your clipboard, paste it into the `~/.config/rclone/rclone.conf` file *on your Raspberry Pi*:

```shell
# On my Raspberry Pi:
nano ~/.config/rclone/rclone.conf
```

The required entry has now been added to your Raspberry Pi's `~/.config/rclone/rclone.conf` file, effectively granting the `rclone` install on your Raspberry Pi access to your Dropbox.

### 3.5 Verify That the Remote Has Been Set Up

Run the below command to check whether the remote has been added to `rclone`:

```shell
rclone listremotes
```

### 3.6 Run Initial Sync of Remote and Local

With `rclone` installed and your remote configured, it is time to connect a local directory to the specific folder on your Dropbox that you wish to sync with.

Ensure that the local directory exists:

```shell
mkdir -p "$LOCAL_FOLDER"
```

Copy down the contents of the remote folder to the local folder:

```shell
rclone copy "$REMOTE_NAME":/"$REMOTE_FOLDER" "$LOCAL_FOLDER"
```

Unless your `$REMOTE_FOLDER` was empty, its contents should now show up in your `$LOCAL_FOLDER`:

```shell
ls "$LOCAL_FOLDER"
```

### 3.7 Run Initial Bidirectional Sync

The first time bidirectionally syncing the local and the remote, run `rclone bisync` with the `--resync` flag.

```shell
rclone bisync --resync --verbose "$LOCAL_FOLDER" "$REMOTE_NAME":/"$REMOTE_FOLDER"
```

### 3.8 Leave Out `--resync` for Successive Sync Runs

Now, you can run the following command whenever you wish to bidirectionally sync your folders (for instance using a cron job):

```shell
rclone bisync --verbose "$LOCAL_FOLDER" "$REMOTE_NAME":/"$REMOTE_FOLDER"
```
