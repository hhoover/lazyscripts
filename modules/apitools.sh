#!/bin/bash
# Installs RS Cloud API tools
set pipper = ""
echo "This will install some CLI tools that interact with the Rackspace APIs"

function os_checker() {
       if [[ $distro = "Redhat/CentOS" ]]; then
                pipper='python-pip'

        elif [[ $distro = "Ubuntu" ]]; then
		pipper='pip'
        else
                echo "Unsupported OS"
        fi
        return 0
}


# Need python-setuptools
function get_setuptools() {
	if [[ ${distro} == "Redhat/CentOS" ]]; then
		yum -q -y install python-setuptools python-pip python-novaclient
	elif [[ ${distro} == "Ubuntu" ]]; then
		apt-get -q -y install python-setuptools python-pip python-novaclient
	else
		echo "[ERROR] Unknown distribution. Exiting"
		return 1
	fi
}

# Rackspace Nova Client
function install_rsnova() {
	echo "Installing Rackspace Nova Client"
	$pipper install --upgrade rackspace-novaclient
	echo "Installed Rackspace Nova Client and all Dependancies"
}

	

get_setuptools
os_checker
install_rsnova
