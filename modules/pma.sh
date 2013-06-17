#!/bin/bash
# Author: Hart Hoover
# Installs phpMyAdmin on CentOS, RHEL, and Ubuntu

function install_phpmyadmin() {
	if [[ ${distro} = "Redhat/CentOS" ]]; then
		if [ -d /usr/share/phpMyAdmin ]; then
			echo "phpMyAdmin might be already installed! Exiting."
			exit 1
		fi
		yum -y -q install phpMyAdmin
		echo "phpMyAdmin installed."
	elif [ ${distro} == "Ubuntu" ]; then
		if [ -d /etc/phpMyAdmin ]; then
			echo "phpMyAdmin might be already installed! Exiting."
			exit 1
		fi
		export DEBIAN_FRONTEND=noninteractive
		apt-get -y -q install phpmyadmin > /dev/null 2>&1
		export DEBIAN_FRONTEND=dialog
		echo "phpMyAdmin installed."
	else
		echo "Unsupported OS. Exiting."
		exit 1
	fi
}

function configure_apache() {
	if [[ ${distro} = "Redhat/CentOS" ]]; then
		mv /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf.orig
		echo "phpMyAdmin.conf backed up to phpMyAdmin.conf.orig"
		cat > /etc/httpd/conf.d/phpMyAdmin.conf <<-EOF
		Alias /phpMyAdmin /usr/share/phpMyAdmin
		Alias /phpmyadmin /usr/share/phpMyAdmin
		<Directory /usr/share/phpMyAdmin/libraries>
		    Order Deny,Allow
		    Deny from All
		    Allow from None
		</Directory>
		EOF
		service httpd reload > /dev/null 2>&1
		echo "Apache restarted"
	elif [ ${distro} == "Ubuntu" ]; then
		echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
		service apache2 reload > /dev/null 2>&1
		echo "Apache restarted"
	else
		echo "Unsupported OS. Exiting."
		exit 1
	fi
}
IP=$( ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' )
echo "Beginning phpMyAdmin installation"
install_phpmyadmin
echo "Configuring Apache"
configure_apache
echo "phpMyAdmin installation complete."
echo "phpMyAdmin is available here: http://${IP}/phpmyadmin"
echo "Your MySQL root credentials are:"
grep -v "client" /root/.my.cnf
exit 0