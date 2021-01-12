#!/usr/bin/env bash

if [[ $(whoami) != 'root' ]]; then
    echo "This script must run under root!"
    exit 1
fi

versionEngine="v2.0.0"

if [[ ! -d "/opt/ffplayout-engine" ]]; then
    echo ""
    echo "------------------------------------------------------------------------------"
    echo "install ffplayout engine"
    echo "------------------------------------------------------------------------------"

    cd /opt
    wget https://github.com/ffplayout/ffplayout-engine/archive/${versionEngine}.tar.gz
    tar xf "${versionEngine}.tar.gz"
    mv "ffplayout-engine-${versionEngine#'v'}" 'ffplayout-engine'
    rm "${versionEngine}.tar.gz"
    cd ffplayout-engine

    virtualenv -p python3 venv
    source ./venv/bin/activate

    pip install -r requirements-base.txt

    mkdir /etc/ffplayout
    mkdir /var/log/ffplayout
    mkdir -p $mediaPath
    mkdir -p $playlistPath

    cp ffplayout.yml /etc/ffplayout/
    chown -R $serviceUser. /etc/ffplayout
    chown $serviceUser. /var/log/ffplayout
    chown $serviceUser. $mediaPath
    chown $serviceUser. $playlistPath

    cp docs/ffplayout-engine.service /etc/systemd/system/
    sed -i "s/User=root/User=$serviceUser/g" /etc/systemd/system/ffplayout-engine.service
    sed -i "s/Group=root/Group=$serviceUser/g" /etc/systemd/system/ffplayout-engine.service

    sed -i "s|\"\/playlists\"|\"$playlistPath\"|g" /etc/ffplayout/ffplayout.yml
    sed -i "s|\"\/mediaStorage|\"$mediaPath|g" /etc/ffplayout/ffplayout.yml

    systemctl enable ffplayout-engine.service

    deactivate
fi
