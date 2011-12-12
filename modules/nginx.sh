#!/bin/bash
# Author: Hart Hoover
# Installs nginx and php-fpm

function set_os() {
	if [ "${distro}" == "Redhat/CentOS" ]; then
		APACHE=httpd
		NGINX_CONFIG_DIR=/etc/nginx
		PACKAGE_INSTALL=yum
	elif [[ "${distro}" == "Ubuntu" ]]; then
		APACHE=apache2
		NGINX_CONFIG_DIR=/etc/nginx
		PACKAGE_INSTALL=apt-get
	fi
}

function RHEL_disable_apache() {
		chkconfig ${APACHE} off
		update-rc.d ${APACHE} disable
	fi
	service ${APACHE} stop > /dev/null > 2>&1
}



function install_nginx() {
	if [ "${distro}" == "Redhat/CentOS" ]; then
		yum -yq install nginx
	elif [[ "${distro}" == "Ubuntu" ]]; then
		apt-get -y install nginx
	fi
}

function configure_nginx() {
	if [ "${distro}" == "Redhat/CentOS" ]; then
	
	elif [[ "${distro}" == "Ubuntu" ]]; then

	fi	
}