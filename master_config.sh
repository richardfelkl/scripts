#!/bin/bash -xe
export SALT_MASTER_DEPLOY_IP=172.17.32.212
export SALT_MASTER_MINION_ID=cfg01.deploy-name.local
export DEPLOY_NETWORK_GW=172.17.32.193
export DEPLOY_NETWORK_NETMASK=255.255.255.192
export DNS_SERVERS=8.8.8.8

echo "Configuring network interfaces"
envsubst < /root/interfaces > /etc/network/interfaces
ifdown ens3; ifup ens3

echo "Preparing metadata model"
mount /dev/cdrom /mnt/
cp -r /mnt/model/model/* /srv/salt/reclass/
umount /dev/cdrom

echo "Configuring salt"
#service salt-master restart
envsubst < /root/minion.conf > /etc/salt/minion.d/minion.conf
service salt-minion restart
while true; do
    salt-key | grep "$SALT_MASTER_MINION_ID" && break
    sleep 5
done
sleep 5
for i in `salt-key -l accepted | grep -v Accepted | grep -v "$SALT_MASTER_MINION_ID"`; do
    salt-key -d $i -y
done
salt-call state.sls linux,openssh,salt,maas.cluster,maas.region

reboot
