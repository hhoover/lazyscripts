#!/bin/bash
# Installs RS Cloud API tools

echo "This will install some CLI tools that interact with the Rackspace APIs"

# Need python-setuptools
function get_setuptools() {
	if [[ ${distro} == "Redhat/CentOS" ]]; then
		yum -q -y install python-setuptools python-pip
	elif [[ ${distro} == "Ubuntu" ]]; then
		apt-get -q -y install python-setuptools python-pip
	else
		echo "[ERROR] Unknown distribution. Exiting"
		return 1
	fi
}

# Rackspace Nova Client
function install_rsnova() {
	echo "Installing Rackspace Nova Client"
	pip install rackspace-novaclient
	echo "Installed Rackspace Nova Client and all Dependancies"
}

	

get_setuptools
install_rsnova
