#!/bin/bash
# Installs recap
# https://github.com/rackerlabs/recap

echo "This will install the recap application  https://github.com/rackerlabs/recap/"

function git_check() {
command -v git >/dev/null 2>&1 || { echo >&2 "I am going to install git"; get_setuptools; }
}

# Need Git
function get_setuptools() {
	if [[ ${distro} == "Redhat/CentOS" ]]; then
		yum -q -y install git
	elif [[ ${distro} == "Ubuntu" ]]; then
		apt-get -q -y install git
	else
		echo "[ERROR] Unknown distribution. Exiting"
		return 1
	fi
}

# Recap - 
function install_recap() {
	echo "Installing recap"
	cd /tmp
	git clone https://github.com/rackerlabs/recap.git
	cd recap
	./recap-installer
	echo "Installed recap"
}

git_check
install_recap
