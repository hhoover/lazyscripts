#!/bin/bash
# Installs RS Cloud API tools

echo "This will install some CLI tools that interact with the Rackspace APIs"

# Need python-setuptools
function get_setuptools() {
	if [[ ${distro} == "Redhat/CentOS" ]]; then
		yum -q -y install python-setuptools
	elif [[ ${distro} == "Ubuntu" ]]; then
		apt-get -q -y install python-setuptools
	else
		echo "[ERROR] Unknown distribution. Exiting"
		return 1
	fi
}

# Cloud Load Balancers
function install_clb() {
	echo "Installing Cloud Load Balancers CLI"
	CLBDIR="/root/.lazyscripts/tools/clb"
	git clone git://github.com/calebgroom/clb.git ${CLBDIR}
	cd ${CLBDIR}
	python setup.py -q install
	echo "CLB installed."
}

# OpenStack Compute
function install_osc() {
	echo "Installing OpenStack Compute CLI tool"
	OSCDIR="/root/.lazyscripts/tools/osc"
	git clone git://github.com/jacobian/openstack.compute.git ${OSCDIR}
	cd ${OSCDIR}
	python setup.py -q install
	echo "OpenStack Compute CLI tool installed."
}

get_setuptools
install_clb
install_osc
