#!/bin/bash
# Author: Hart Hoover
# purpose: Installs and configures Varnish 3

function get_varnish() {
	if [[ $distro = "Redhat/CentOS" ]]; then
		echo "Adding Varnish Repository and installing varnish"
		rpm --nosignature -i http://repo.varnish-cache.org/redhat/varnish-3.0/el5/noarch/varnish-release-3.0-1.noarch.rpm > /dev/null 2>&1
		yum -q -y install varnish
		"Varnish installed."
		chkconfig varnish on
	elif [[ $distro = "Ubuntu" ]]; then
		echo "Adding Varnish Repository and installing varnish"
		curl -s http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add - > /dev/null 2>&1
		echo "deb http://repo.varnish-cache.org/ubuntu/ lucid varnish-3.0" >> /etc/apt/sources.list
		apt-get update > /dev/null 2>&1
		apt-get -y -q install varnish > /dev/null 2>&1
		"Varnish installed."
	else
		echo "Unsupported OS"
		exit 1
	fi
}

function configure_varnish() {
	if [[ $distro = "Redhat/CentOS" ]]; then
		echo "Fetching standard Varnish config from Cloud Files..."
		sed -i 's/VARNISH_LISTEN_PORT=6081/VARNISH_LISTEN_PORT=80/g' /etc/sysconfig/varnish
		wget --quiet -P /etc/varnish/ http://c460059.r59.cf2.rackcdn.com/cent_default3.vcl
		mv /etc/varnish/default.vcl /etc/varnish/default.vcl.orig
		mv /etc/varnish/cent_default3.vcl /etc/varnish/default.vcl
		echo "Varnish Configured. Please configure Apache."
	elif [[ $distro = "Ubuntu" ]]; then
		echo "Fetching standard Varnish config from Cloud Files..."
		wget --quiet -P /etc/varnish/ http://c460059.r59.cf2.rackcdn.com/cent_default3.vcl
		mv /etc/varnish/default.vcl /etc/varnish/default.vcl.orig
		mv /etc/varnish/cent_default3.vcl /etc/varnish/default.vcl
		sed -i 's/^DAEMON_OPTS="-a :6081/DAEMON_OPTS="-a :80/g' /etc/default/varnish
		echo "Varnish Configured. Please configure Apache."
	else
		echo "Unsupported OS"
		exit 1
	fi
}

get_varnish
configure_varnish