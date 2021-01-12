#!/usr/bin/env bash

if [[ $(whoami) != 'root' ]]; then
    echo "This script must run under root!"
    exit 1
fi

echo ""
echo "------------------------------------------------------------------------------"
echo "creating selinux rules"
echo "------------------------------------------------------------------------------"

if [[ $(getsebool httpd_can_network_connect | awk '{print $NF}') == "off" ]]; then
    setsebool httpd_can_network_connect on -P
fi

if [[ ! $(semanage port -l | grep http_port_t | grep "8001") ]]; then
    semanage port -a -t http_port_t -p tcp 8001
fi

if [[ ! $(semodule -l | grep gunicorn) ]]; then
cat <<EOF > gunicorn.te
module gunicorn 1.0;

require {
type init_t;
type httpd_sys_content_t;
type unreserved_port_t;
class tcp_socket name_connect;
type etc_t;
type sudo_exec_t;
class file { create execute execute_no_trans getattr ioctl lock map open read unlink write };
class lnk_file { getattr read };
}

#============= init_t ==============

#!!!! This avc is allowed in the current policy
allow init_t etc_t:file write;

#!!!! This avc is allowed in the current policy
#!!!! This av rule may have been overridden by an extended permission av rule
allow init_t httpd_sys_content_t:file { create execute execute_no_trans getattr ioctl lock map open read unlink write };

#!!!! This avc is allowed in the current policy
allow init_t httpd_sys_content_t:lnk_file { getattr read };

#!!!! This avc can be allowed using the boolean 'nis_enabled'
allow init_t unreserved_port_t:tcp_socket name_connect;

#!!!! This avc is allowed in the current policy
allow init_t sudo_exec_t:file { execute execute_no_trans map open read };
EOF

    checkmodule -M -m -o gunicorn.mod gunicorn.te
    semodule_package -o gunicorn.pp -m gunicorn.mod
    semodule -i gunicorn.pp

    rm -f gunicorn.*
fi

if [[ ! $(semodule -l | grep "custom-http") ]]; then
cat <<EOF > custom-http.te
module custom-http 1.0;

require {
type init_t;
type httpd_sys_content_t;
class file { create lock unlink write };
}

#============= init_t ==============
allow init_t httpd_sys_content_t:file unlink;

#!!!! This avc is allowed in the current policy
allow init_t httpd_sys_content_t:file { create lock write };
EOF

    checkmodule -M -m -o custom-http.mod custom-http.te
    semodule_package -o custom-http.pp -m custom-http.mod
    semodule -i custom-http.pp

    rm -f custom-http.*
fi

if [[ ! $(semodule -l | grep "custom-fileop") ]]; then
cat <<EOF > custom-fileop.te
module custom-fileop 1.0;

require {
type init_t;
type httpd_sys_content_t;
type usr_t;
class file { create rename unlink write };
class dir { create rmdir };
}

#============= init_t ==============
allow init_t httpd_sys_content_t:file rename;

#!!!! This avc is allowed in the current policy
allow init_t usr_t:dir create;
allow init_t usr_t:dir rmdir;

#!!!! This avc is allowed in the current policy
allow init_t usr_t:file create;
allow init_t usr_t:file { rename unlink write };

EOF

    checkmodule -M -m -o custom-fileop.mod custom-fileop.te
    semodule_package -o custom-fileop.pp -m custom-fileop.mod
    semodule -i custom-fileop.pp

    rm -f custom-fileop.*
fi
