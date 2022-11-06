# QTier Daemon

A Tweak to convert “快贴” into a daemon process, so that it can be run on an iPhone server to sync the clipboard seamlessly.


## Usage

1. Download 快贴, Register & Login & Setup the Clip Sync

2. Install this tweak & estertion's AppLink

3. Goto `daemon_files`:
    - Put `qtier_daemon` folder into `/var/mobile/qtier_daemon`
    - Put `misty.qtierdaemon.plist` into `/Library/LaunchDaemons`
    - Run `launchctl start /Library/LaunchDaemons/misty.qtierdaemon.plist`

4. Install blank_alive tool in my other repo, so that iCloud keeps syncing your clipboard 