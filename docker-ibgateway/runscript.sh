#!/bin/bash

/opt/IBController/Scripts/DisplayBannerAndLaunch.sh &
sleep 1
tail -f $(find $LOG_PATH -maxdepth 1 -type f -printf "%T@ %p\n" | sort -n | tail -n 1 | cut -d' ' -f 2-) &

jupyter lab --ip=0.0.0.0 --allow-root