# How to build ?
```
sudo docker  build --rm -t="krystism/openstack-nova-compute" .
```
# How to use ?
Before you start a nova-compute instance, you need these services running:
* mysql-server
* rabbitmq
* keystone
* glance-api & glance-registry
* nova-api & nova-cert & nova-consoleauth & nova-scheduler & nova-conductor & nova-novncproxy

Both [mysql-server](https://registry.hub.docker.com/_/mysql/) and [rabbitmq](https://registry.hub.docker.com/_/rabbitmq/) images
are available, you can pull from docker hub. 

Of cource, you can replace mysql-server with [mariadb](https://registry.hub.docker.com/_/mariadb/).

To start mysql-server & rabbitmq, you just need run these scripts as follows:
```
docker run -d -e RABBITMQ_NODENAME=rabbitmq -h rabbitmq --name rabbitmq rabbitmq:latest
docker run -d -e MYSQL_ROOT_PASSWORD=MYSQL_DBPASS -h mysql --name mysql -d mariadb:latest
```
Then you should start a keystone service, you can use my keystone image to create a container with keystone to meet it:
```
docker run -d  --link mysql:mysql --name keystone -h keystone krystism/openstack-keystone:latest
```
The keystone service may take some time to start, you need wait for the service working before you do next.

Once the keystone service is running, you also need a glance service. if you just want to try openstack, fortunately, 
you can use my glance image to quickly deploy it:
```
docker run -d\
      	--link mysql:mysql \
       	--link keystone:keystone \
	-e OS_USERNAME=admin \
	-e OS_PASSWORD=ADMIN_PASS \
	-e OS_AUTH_URL=http://keystone:5000/v2.0 \
	-e OS_TENANT_NAME=admin \
	--name glance \
	-h glance \
	krystism/openstack-glance:latest
```

Next, we need a server running nova common service, such as nova-api,nova-conductor,etc. we name this server as 
controller, you can deploy it quickly with my nova-controller image:
	
```
	docker run -d\
      	--link mysql:mysql \
       	--link keystone:keystone \
	--link rabbitmq:rabbitmq \
	--link glance:glance \
	-e OS_USERNAME=admin \
	-e OS_PASSWORD=ADMIN_PASS \
	-e OS_AUTH_URL=http://keystone:5000/v2.0 \
	-e OS_TENANT_NAME=admin \
	--privileged \
	--name controller \
	-h controller \
	krystism/openstack-nova-controller:latest
```
**Atention: The option *--privileged* is requited, or you can not update iptable in your container!**

It also may take some time, you can fetch logs to watch its process:
```
docker logs controller
```
Once complete, you can enter container using *exec* to check if the services work or not.
```
docker exec -t -i controller bash
cd /root
source admin-openrc.sh
nova service-list
```
Last, We deploy two compute nodes(you can repeat it if you want to more nodes):
```
docker run -d \
--link mysql:mysql \
  --link keystone:keystone \
	--link rabbitmq:rabbitmq \
	--link glance:glance \
	--link controller:controller \
	-e OS_USERNAME=admin \
	-e OS_PASSWORD=ADMIN_PASS \
	-e OS_AUTH_URL=http://keystone:5000/v2.0 \
	-e OS_TENANT_NAME=admin \
	--privileged \
	--name node1 \
	-h node1 \
	krystism/openstack-nova-compute:latest
docker run -d\
  --link mysql:mysql \
  --link keystone:keystone \
	--link rabbitmq:rabbitmq \
	--link glance:glance \
	--link controller:controller \
	-e OS_USERNAME=admin \
	-e OS_PASSWORD=ADMIN_PASS \
	-e OS_AUTH_URL=http://keystone:5000/v2.0 \
	-e OS_TENANT_NAME=admin \
	--privileged \
	--name node2 \
	-h node2 \
	krystism/openstack-nova-compute:latest
```
After all off the works above complate, you can run *nova service-list*, as expected, you can find that nova-compute service is up:
```
docker exec -t -i controller bash
nova service-list
```
# Possible Problem
I do not recommand you write a script to run all the command above or use fig, because different services to start may take
different time, you can not ensure the last service is running when you start current service. For example, if mysql
service does not work, the keystone service may fail to start, you must ensure mysql is running before create a keystone
instance.
