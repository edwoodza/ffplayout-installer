#!/usr/bin/env bash

versionFrontend="v2.1.5"

if [[ $(whoami) != 'root' ]]; then
    echo "This script must run under root!"
    exit 1
fi

if [[ ! -d "/var/www/ffplayout-frontend" ]]; then
    echo ""
    echo "------------------------------------------------------------------------------"
    echo "install ffplayout-frontend"
    echo "------------------------------------------------------------------------------"

    cd /var/www
    wget https://github.com/ffplayout/ffplayout-frontend/archive/${versionFrontend}.tar.gz
    tar xf "${versionFrontend}.tar.gz"
    mv "ffplayout-frontend-${versionFrontend#'v'}" 'ffplayout-frontend'
    rm "${versionFrontend}.tar.gz"
    cd ffplayout-frontend

    ln -s "$mediaPath" /var/www/ffplayout-frontend/static/

    npm install

cat <<EOF > ".env"
BASE_URL='http://$domainName'
API_URL='/'
EOF

    npm run build

    chown $serviceUser. -R /var/www

    if [[ ! -f "$nginxConfig/ffplayout.conf" ]]; then
        cp docs/ffplayout.conf "$nginxConfig/"

        origin=$(echo "$domainName" | sed 's/\./\\\\./g')

        sed -i "s/ffplayout.local/$domainName/g" $nginxConfig/ffplayout.conf
        sed -i "s/ffplayout\\\.local/$origin/g" $nginxConfig/ffplayout.conf

        if [[ "$(grep -Ei 'debian|buntu|mint' /etc/*release)" ]]; then
            ln -s $nginxConfig/ffplayout.conf /etc/nginx/sites-enabled/
        fi
    fi

    systemctl reload nginx
fi
