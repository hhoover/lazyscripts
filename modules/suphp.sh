#!/bin/bash
# Author: Hart Hoover
# Code added by Curtus Regnier and Jordan Callicoat
# Purpose: to convert a server from mod_php to mod_suphp
# Works with CentOS, RHEL, and Ubuntu
function lsapdocs() {
	if [[ "${distro}" == "Redhat/CentOS" ]]
		then
    httpd -S 2>&1|grep -v "^Warning:"|egrep "\/.*\/"|sed 's/.*(\(.*\):.*).*/\1/'|sort|uniq|xargs cat|grep -i DocumentRoot|egrep -v "^#"|awk '{print $2}'|sort|uniq
	elif [[ "${distro}" == "Ubuntu" ]]
		then
	apache2ctl -S 2>&1|grep -v "^Warning:"|egrep "\/.*\/"|sed 's/.*(\(.*\):.*).*/\1/'|sort|uniq|xargs cat|grep -i DocumentRoot|egrep -v "^#"|awk '{print $2}'|sort|uniq
else
	echo "Unsupported OS. You're on your own."
	exit 1
fi
}

function backup_perms() {
	if [[ $distro == "Redhat/CentOS" ]]; then
		echo "Installing ACL for permission backup"
		yum -y install acl > /dev/null 2>&1
		echo "ACL installed."
	elif [[ $distro == "Ubuntu" ]]; then
		echo "Installing ACL for permission backup"
		apt-get -y install acl > /dev/null 2>&1
		echo "ACL installed."
	else
		echo "Unsupported OS"
		exit 1
	fi
	
while [[ -z "$DIR" ]]; do
	read -p "Please provide the parent path to the website document roots [ex: /var/www/vhosts] " -e DIR
done

	echo "Backing up permissions."
	getfacl -R $DIR > /root/.docrootperms.acl
}

function disable_mod_php() {
	if [[ $distro == "Redhat/CentOS" ]]; then
		mv /etc/httpd/conf.d/php.conf /etc/httpd/conf.d/php.conf.disabled
		touch /etc/httpd/conf.d/php.conf
	elif [[ $distro == "Ubuntu" ]]; then
		a2dismod php5 > /dev/null 2>&1
	else
		echo "Unsupported OS"
		exit 1
	fi
}

function install_mod_suphp() {
	if [[ $distro == "Redhat/CentOS" ]]; then
		yum -y -q install mod_suphp > /dev/null 2>&1
		cat > /etc/httpd/conf.d/mod_suphp.conf <<-EOF
		# This is the Apache server configuration file providing suPHP support..
		# It contains the configuration directives to instruct the server how to
		# serve php pages while switching to the user context before rendering.

		LoadModule suphp_module modules/mod_suphp.so

		### Uncomment to activate mod_suphp
		AddHandler x-httpd-php .php .php3 .php4 .php5
		suPHP_AddHandler x-httpd-php

		# This option tells mod_suphp if a PHP-script requested on this server (or
		# VirtualHost) should be run with the PHP-interpreter or returned to the
		# browser "as it is".
		suPHP_Engine on

		# This option tells mod_suphp which path to pass on to the PHP-interpreter
		# (by setting the PHPRC environment variable).
		# Do \*NOT\* refer to a file but to the directory the file resists in.
		#
		# E.g.: If you want to use "/path/to/server/config/php.ini", use "suPHP_Config
		# /path/to/server/config".
		#
		# If you don't use this option, PHP will use its compiled in default path.
		suPHP_ConfigPath /etc
		EOF
		cat > /etc/suphp.conf <<-EOF
		[global]
		;Path to logfile
		logfile=/var/log/suphp.log

		;Loglevel
		loglevel=info

		;User Apache is running as
		webserver_user=apache

		;Path all scripts have to be in
		docroot=/

		;Path to chroot() to before executing script
		;chroot=/mychroot

		; Security options
		allow_file_group_writeable=false
		allow_file_others_writeable=false
		allow_directory_group_writeable=false
		allow_directory_others_writeable=false

		;Check wheter script is within DOCUMENT_ROOT
		check_vhost_docroot=true

		;Send minor error messages to browser
		errors_to_browser=true

		;PATH environment variable
		env_path=/bin:/usr/bin

		;Umask to set, specify in octal notation
		umask=0022

		; Minimum UID
		min_uid=500

		; Minimum GID
		min_gid=500

		; Use correct permissions for mod_userdir sites
		handle_userdir=true

		[handlers]
		;Handler for php-scripts
		x-httpd-php=php:/usr/bin/php-cgi

		;Handler for CGI-scripts
		x-suphp-cgi=execute:!self
		EOF
		service httpd restart > /dev/null 2>&1
	elif [[ $distro == "Ubuntu" ]]; then
		apt-get -y -q install suphp-common libapache2-mod-suphp > /dev/null 2>&1
		cat > /etc/apache2/mods-available/suphp.conf <<-EOF
		<IfModule mod_suphp.c>
		        AddType application/x-httpd-suphp .php .php3 .php4 .php5 .phtml
		        suPHP_AddHandler application/x-httpd-suphp

		    <Directory />
		        suPHP_Engine on
		    </Directory>

		    # By default, disable suPHP for debian packaged web applications as files
		    # are owned by root and cannot be executed by suPHP because of min_uid.
		    <Directory /usr/share>
		        suPHP_Engine off
		    </Directory>

		# # Use a specific php config file (a dir which contains a php.ini file)
		#       suPHP_ConfigPath /etc/php4/cgi/suphp/
		# # Tells mod_suphp NOT to handle requests with the type <mime-type>.
		#       suPHP_RemoveHandler <mime-type>
		</IfModule>
		EOF
		cat > /etc/suphp/suphp.conf <<-EOF
		[global]
		;Path to logfile
		logfile=/var/log/suphp/suphp.log

		;Loglevel
		loglevel=info

		;User Apache is running as
		webserver_user=www-data

		;Path all scripts have to be in
		docroot=/var/www:${HOME}/public_html

		;Path to chroot() to before executing script
		;chroot=/mychroot

		; Security options
		allow_file_group_writeable=false
		allow_file_others_writeable=false
		allow_directory_group_writeable=false
		allow_directory_others_writeable=false

		;Check wheter script is within DOCUMENT_ROOT
		check_vhost_docroot=true

		;Send minor error messages to browser
		errors_to_browser=false

		;PATH environment variable
		env_path=/bin:/usr/bin

		;Umask to set, specify in octal notation
		umask=0022

		; Minimum UID
		min_uid=1000

		; Minimum GID
		min_gid=1000

		[handlers]
		;Handler for php-scripts
		application/x-httpd-suphp="php:/usr/bin/php-cgi"

		;Handler for CGI-scripts
		x-suphp-cgi="execute:!self"
		EOF
		a2enmod suphp  > /dev/null 2>&1
		service apache2 restart > /dev/null 2>&1
	else
		echo "Something went wrong! Please file a bug report at https://github.com/hhoover/lazyscripts"
		exit 1
	fi
}

echo "Apache document roots:"
lsapdocs
backup_perms
echo "Moving mod_php out of the way."
disable_mod_php
echo "Installing mod_suphp."
install_mod_suphp
echo "Mod_suphp installed and configured."
echo "Current permissions backed up to /root/.docrootperms.acl"
echo "Current permissions can be restored with setfacl --restore=/root/.docrootperms.acl"
echo "I like salsa!"