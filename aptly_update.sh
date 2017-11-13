#!/bin/bash
MIRROR_LIST="$(sudo -i -u aptly aptly mirror list --raw)"
if [ $MIRROR_LIST != "" ]; then
    echo "===> Updating all mirrors"
    echo $MIRROR_LIST | grep -E '*' | xargs -n 1 sudo -i -u aptly aptly mirror update
fi
PUBLISH_LIST="$(sudo -i -u aptly aptly publish list --raw)"
if [ "$PUBLISH_LIST" != "" ]; then
    echo "===> Deleting all publishes"
    echo $PUBLISH_LIST | awk '{print $2, $1}' | xargs -n2 sudo -i -u aptly aptly publish drop
fi
SNAPSHOT_LIST="$(sudo -i -u aptly aptly snapshot list --raw)"
if [ "$SNAPSHOT_LIST" != "" ]; then
    echo "===> Deleting all snapshots"
    echo $SNAPSHOT_LIST | grep -E '*' | xargs -n 1 sudo -i -u aptly aptly snapshot drop
fi
sudo -i -u aptly aptly_mirror_update.sh -v -s
sudo -i -u aptly nohup aptly api serve --no-lock > /dev/null 2>&1 </dev/null &
sudo -i -u aptly aptly-publisher --timeout=1200 publish -v -c /etc/aptly-publisher.yaml --url http://127.0.0.1:8080 --recreate
ps aux  |  grep -i "aptly api serve"  |  awk '{print $2}'  |  xargs kill -9
sudo -i -u aptly aptly db cleanup