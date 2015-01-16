#!/bin/bash
# To create the Identity service credentials
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}
GLANCE_HOST=${GLANCE_HOST:-glance}
NOVA_USER_NAME=${NOVA_USER_NAME:-nova}
NOVA_PASSWORD=${NOVA_PASSWORD:-NOVA_PASS}
NOVA_HOST=${NOVA_HOST:-$HOSTNAME}
export OS_USERNAME=${OS_USERNAME:-admin}
export OS_PASSWORD=${OS_PASSWORD:-ADMIN_PASS}
export OS_TENANT_NAME=${OS_TENANT_NAME:-admin}
export OS_AUTH_URL=${OS_AUTH_URL:-http://${KEYSTONE_HOST}:35357/v2.0}

# update nova.conf
CONFIG_FILE=/etc/nova/nova.conf
sed -i "s#^auth_uri.*=.*#auth_uri = http://${KEYSTONE_HOST}:5000/v2.0#" $CONFIG_FILE
sed -i "s#^identity_uri.*=.*#identity_uri = http://${KEYSTONE_HOST}:35357#" $CONFIG_FILE
sed -i "s#^admin_user.*=.*#admin_user = ${NOVA_USER_NAME}#" $CONFIG_FILE
sed -i "s#^admin_password.*=.*#admin_password = ${NOVA_PASSWORD}#" $CONFIG_FILE
RABBITMQ_HOST=${RABBITMQ_HOST:-rabbitmq}
RABBITMQ_USER=${RABBITMQ_USER:-guest}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-guest}
sed -i "s#^rabbit_host.*=.*#rabbit_host = ${RABBITMQ_HOST}#" $CONFIG_FILE
sed -i "s#^rabbit_password.*=.*#rabbit_password = ${RABBITMQ_PASSWORD}#" $CONFIG_FILE
MY_IP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
sed -i "s#^my_ip.*=.*#my_ip = ${MY_IP}#" $CONFIG_FILE
sed -i "s#^vncserver_listen.*=.*#vncserver_listen = 0.0.0.0#" $CONFIG_FILE
sed -i "s#^vncserver_proxyclient_address*=.*#vncserver_proxyclient_address = ${MY_IP}#" $CONFIG_FILE
CONTROLLER_HOST=${CONTRLLER_HOST:-controller}
sed -i "s#^novncproxy_base_url*=.*#novncproxy_base_url = http://${CONTROLLER_HOST}:6080/vnc_auto.html#" $CONFIG_FILE
cat >>$CONFIG_FILE <<EOF
[glance]
host = $GLANCE_HOST
EOF

# sync the database

# create a admin-openrc.sh file
ADMIN_OPENRC=/root/admin-openrc.sh
cat >$ADMIN_OPENRC <<EOF
export OS_TENANT_NAME=$OS_TENANT_NAME
export OS_USERNAME=$OS_USERNAME
export OS_PASSWORD=$OS_PASSWORD
export OS_AUTH_URL=$OS_AUTH_URL
EOF

#start nova service
libvirtd &
nova-network &
nova-api-metadata &
nova-compute
