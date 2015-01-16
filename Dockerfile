FROM krystism/openstack_base
MAINTAINER krystism "krystism@gmail.com"
# install packages
RUN apt-get -y install python-glanceclient python-keystoneclient python-novaclient
RUN apt-get -y install nova-compute nova-network nova-api-metadata

# remove the SQLite database file
RUN rm -f /var/lib/nova/nova.sqlite

EXPOSE 8775 67

#copy nova config file
COPY nova.conf /etc/nova/nova.conf

# add bootstrap script and make it executable
COPY bootstrap.sh /etc/bootstrap.sh
RUN chown root.root /etc/bootstrap.sh
RUN chmod 744 /etc/bootstrap.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
