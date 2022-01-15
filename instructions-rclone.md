https://howchoo.com/pi/how-to-install-dropbox-on-a-raspberry-pi

### 1. Update your Raspberry Pi.

`sudo apt update && sudo apt upgrade`

### 2. Download the `rclone` install script from rclone.org instead of using `apt` (the `rclone` version available in the Raspbian repository is usually old).

`wget https://rclone.org/install.sh`

### 3. Run the install script.

`sudo bash ./install.sh`

### 4. Use VNC Viewer to get a screen view of your Raspberry Pi. Else, follow above instructions in above link for headless *`rclone` setup*.

`rclone config`

### 5. Set environment variables.

When prompted in the config in the previous step, I set the name of the remote Dropbox to "dropbox-books-henrik".

Set a variable to the same value:

`REMOTE_NAME=dropbox-books-henrik`

The following is the name of the specific folder under the remote previously specified:

`REMOTE_FOLDER=dropbox_books`

### 6. Create local Dropbox folder to sync with.

`LOCAL_FOLDER=$HOME/dropbox-books-henrik`

`mkdir $LOCAL_FOLDER`

### 7. Copy down all the contents of the remote folder to the local folder for an initial setup.

`rclone copy $REMOTE_NAME:/$REMOTE_FOLDER $LOCAL_FOLDER`

### 8. Install `rclonesync` for bidirectional syncing.

`sudo curl https://raw.githubusercontent.com/cjnaz/rclonesync-V2/master/rclonesync --output /usr/local/bin/rclonesync && sudo chmod +x /usr/local/bin/rclonesync`

`mkdir ~/.rclonesyncwd`

### 9. Set up `rclonesync`.
`rclonesync --first-sync $REMOTE_NAME:/$REMOTE_FOLDER $LOCAL_FOLDER`

### 10. Now, you can run the following command whenever you wish to sync your folders (e.g., using a cronjob):

`rclonesync --verbose $REMOTE_NAME:/$REMOTE_FOLDER $LOCAL_FOLDER`

### 11. I put the command in a separate file called `run_rclonesync.sh`. Remember to change the execution privileges of the script.

`chmod +x run_rclonesync.sh`

### 12. I used the following crontab settings to run the command every 3 hours:

`0 3 * * * bash /home/pi/devel/rpi-books/run_rclonesync.sh >> /home/pi/devel/rpi-books/logs/run_rclonesync.out 2>&1`
