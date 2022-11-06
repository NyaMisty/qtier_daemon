#!/bin/bash

set -e

CURDIR=$(realpath "$(dirname "$0")")
/usr/local/bin/applink > /dev/null
APPDIR=$(realpath /var/mobile/Documents/App-link/App/com.cissusnar.clipManager/clipManager.app)
if ! [ -f $APPDIR/clipManager_daemon ]; then
	cp $CURDIR/clipManager_daemon $APPDIR
fi

DATADIR=$(realpath /var/mobile/Documents/App-link/Data/com.cissusnar.clipManager)
(cd $DATADIR; $APPDIR/clipManager_daemon)

