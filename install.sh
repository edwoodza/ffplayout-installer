#!/usr/bin/env bash

versionFrontend="v2.1.0"

if [[ $(whoami) != 'root' ]]; then
    echo "This script must run under root!"
    exit 1
fi

if [[ "$(grep -Ei 'centos|fedora' /etc/*release)" ]]; then
    serviceUser="nginx"
else
    serviceUser="www-data"
fi

# get sure that we have our correct PATH
export PATH=$PATH:/usr/local/bin
export NUXT_TELEMETRY_DISABLED=1

CURRENTPATH=$PWD

echo ""
echo "------------------------------------------------------------------------------"
echo "ffplayout domain name (like: example.org), or IP"
echo "------------------------------------------------------------------------------"
echo ""

read -p "domain name :$ " domainName

if ! ffmpeg -version &> /dev/null; then
    echo ""
    echo "------------------------------------------------------------------------------"
    echo "compile and install (nonfree) ffmpeg:"
    echo "------------------------------------------------------------------------------"
    echo ""
    while true; do
        read -p "Do you wish to compile ffmpeg? (Y/n) :$ " yn
        case $yn in
            [Yy]* ) compileFFmpeg="y"; break;;
            [Nn]* ) compileFFmpeg="n"; break;;
            * ) (
                echo "------------------------------------"
                echo "Please answer yes or no!"
                echo ""
                );;
        esac
    done
fi

if [[ ! -d /usr/local/srs ]]; then
    echo ""
    echo "------------------------------------------------------------------------------"
    echo "install and srs rtmp/hls server:"
    echo "------------------------------------------------------------------------------"
    echo ""
    while true; do
        read -p "Do you wish to install srs? (Y/n) :$ " yn
        case $yn in
            [Yy]* ) compileSRS="y"; break;;
            [Nn]* ) compileSRS="n"; break;;
            * ) (
                echo "------------------------------------"
                echo "Please answer yes or no!"
                echo ""
                );;
        esac
    done
fi

echo ""
echo "------------------------------------------------------------------------------"
echo "path to media storage, default: /opt/tv-media"
echo "------------------------------------------------------------------------------"
echo ""

read -p "media path :$ " mediaPath

if [[ -z "$mediaPath" ]]; then
    mediaPath="/opt/tv-media"
fi

echo ""
echo "------------------------------------------------------------------------------"
echo "playlist path, default: /opt/playlists"
echo "------------------------------------------------------------------------------"
echo ""

read -p "playlist path :$ " playlistPath

if [[ -z "$playlistPath" ]]; then
    playlistPath="/opt/playlists"
fi


################################################################################
## Install functions
################################################################################

# install system packages
source $CURRENTPATH/scripts/system.sh

# install app collection

if [[ $compileFFmpeg == 'y' ]]; then
    source $CURRENTPATH/scripts/ffmpeg.sh
fi

if [[ $compileSRS == 'y' ]]; then
    source $CURRENTPATH/scripts/srs.sh
fi

source $CURRENTPATH/scripts/engine.sh
source $CURRENTPATH/scripts/api.sh
source $CURRENTPATH/scripts/frontend.sh

if ! grep -q "ffplayout-engine.service" "/etc/sudoers"; then
  echo "$serviceUser  ALL = NOPASSWD: /bin/systemctl start ffplayout-engine.service, /bin/systemctl stop ffplayout-engine.service, /bin/systemctl reload ffplayout-engine.service, /bin/systemctl restart ffplayout-engine.service, /bin/systemctl status ffplayout-engine.service, /bin/systemctl is-active ffplayout-engine.service, /bin/journalctl -n 1000 -u ffplayout-engine.service" >> /etc/sudoers
fi

if [[ "$(grep -Ei 'centos|fedora' /etc/*release)" ]]; then
    echo ""
    echo "------------------------------------------------------------------------------"
    echo "you run a rhel like system, which is not widely tested"
    echo "this OS needs some SeLinux rules"
    echo "check scripts/selinux.sh if you can live with it, and run that script manually"
    echo "------------------------------------------------------------------------------"
    echo ""
fi

echo ""
echo "------------------------------------------------------------------------------"
echo "installation done..."
echo "------------------------------------------------------------------------------"
echo ""
