#!/usr/bin/env bash

# app versions (master is to unstable)
versionApi="v2.2.0-r1"

if [[ $(whoami) != 'root' ]]; then
    echo "This script must run under root!"
    exit 1
fi

if [[ ! -d "/var/www/ffplayout-api" ]]; then
    echo ""
    echo "------------------------------------------------------------------------------"
    echo "install ffplayout-api"
    echo "------------------------------------------------------------------------------"

    cd /var/www
    wget https://github.com/ffplayout/ffplayout-api/archive/${versionApi}.tar.gz
    tar xf "${versionApi}.tar.gz"
    mv "ffplayout-api-${versionApi#'v'}" 'ffplayout-api'
    rm "${versionApi}.tar.gz"
    cd ffplayout-api

    virtualenv -p python3 venv
    source ./venv/bin/activate

    pip install -r requirements-base.txt

    cd ffplayout

    secret=$(python manage.py shell -c 'from django.core.management import utils; print(utils.get_random_secret_key())')

    sed -i "s/---a-very-important-secret-key\:-generate-it-new---/$secret/g" ffplayout/settings/production.py
    sed -i "s/localhost/$domainName/g" ../docs/db_data.json

    python manage.py makemigrations && python manage.py migrate
    python manage.py collectstatic
    python manage.py loaddata ../docs/db_data.json
    python manage.py createsuperuser

    deactivate

    chown $serviceUser. -R /var/www

    cd ..

    cp docs/ffplayout-api.service /etc/systemd/system/

    sed -i "s/User=root/User=$serviceUser/g" /etc/systemd/system/ffplayout-api.service
    sed -i "s/Group=root/Group=$serviceUser/g" /etc/systemd/system/ffplayout-api.service

    sed -i "s/'localhost'/'localhost', \'$domainName\'/g" /var/www/ffplayout-api/ffplayout/ffplayout/settings/production.py
    sed -i "s/ffplayout\\.local/$domainName\'\n    \'https\\:\/\/$domainName/g" /var/www/ffplayout-api/ffplayout/ffplayout/settings/production.py

    systemctl enable ffplayout-api.service
    systemctl start ffplayout-api.service
fi
