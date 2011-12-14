#!/bin/bash
# Installs Nginx as a webserver with php-fpm
# Author: James Dewey


#Check for OS and set needed stuff:

if [ ! -a /etc/redhat-release ]	 && [ "$(lsb_release -d | awk '{print $2}')" == "Ubuntu" ]
then
	OS=ubuntu
elif [ ! -a /etc/redhat-release ] && [ "$(lsb_release -r | awk '{print $2}')" == "10.04" ]
then
	echo "Nginx Installer is not supported on ubuntu 10.04 due to not having PHP-FPM available in the repo."
	exit 0
fi


#Check for Repo
check_repo() {
	if [ "${OS}" == "ubuntu" ]
	then
		if [ -z "$(grep -Ri "nginx" /etc/apt/)" ]
		then
			REPOEXISTS=0
		else
			REPOEXISTS=1
		fi
	fi
}


# Set up Repo if it's not there.  
create_repo() {
	if [ "${OS}" == "ubuntu" ]
	then
		echo -e "\n\n# Nginx Repo" >> /etc/apt/sources.list
		echo "deb http://nginx.org/packages/ubuntu/ lucid nginx" >> /etc/apt/sources.list
		echo "deb-src http://nginx.org/packages/ubuntu/ lucid nginx" >> /etc/apt/sources.list
	fi
}



#Check for repo and add if needed.
echo "Checking if Nginx Repo exists..."
check_repo
if [ "${REPOEXISTS}" == 0 ]
then
	echo "Repo not found, adding to configuration."
	create_repo
else
	echo "Repo Already Exists, no changes made."
fi


#Disable apache.
if [ "${OS}" == "ubuntu" ]
then
	echo "Stopping Apache and disabling it on boot.."
	service apache2 stop > /dev/null 2>&1
	update-rc.d apache2 disable > /dev/null 2>&1
fi

#Check for if  Nginx is installed
if [ "${OS}" == "ubuntu" ]
then
	echo "Checking for existing nginx installation..."
	if [ -z "$(dpkg -l | grep -i nginx)" ]
	then
		APACHEINSTALLED=0
	else	
 		echo "Nginx is already installed, purge it and try the installation again."
		exit
	fi
fi


#Install Nginx
if [ "${OS}" == "ubuntu" ] && [ "${APACHEINSTALLED}" == 0 ]
then
	echo "Installing Nginx..."

	gpg --keyserver pgpkeys.mit.edu --recv-key  ABF5BD827BD9BF62 > /dev/null 2>&1
	gpg -a --export ABF5BD827BD9BF62 | sudo apt-key add - > /dev/null 2>&1
	apt-get  update > /dev/null 2>&1
	apt-get -y install nginx > /dev/null 2>&1
fi



#Set up configurations for vhosts + default vhost + php-fpm
if [ "${OS}" == "ubuntu" ] 
then
	mkdir /var/www/vhosts/ > /dev/null 2>&1
	mkdir /var/www/vhosts/default > /dev/null 2>&1
	mkdir /etc/nginx/vhost.d > /dev/null 2>&1
	head -$((`wc -l /etc/nginx/nginx.conf | awk '{print $1}'` - 1)) /etc/nginx/nginx.conf > /tmp/nginx.conf
	cat /tmp/nginx.conf > /etc/nginx.conf
	echo -e "include /etc/nginx/vhost.d/*.conf;\n }" >> /etc/nginx.conf
	rm -rf /tmp/nginx.conf
	echo "server {

	listen  80 default_server; 

	server_name _;

	access_log  /var/log/nginx/access.log;
	error_log   /var/log/nginx/error.log error;

	location / {
		root   /var/www/vhosts/default;
		index  index.php index.html index.htm;

	}

	location ~ \.php$ {
		fastcgi_pass   php5-fpm-sock;
		fastcgi_index  index.php;
		fastcgi_param  SCRIPT_FILENAME  /var/www/vhosts/default$fastcgi_script_name;
		include fastcgi_params;
	}

}" > /etc/nginx/vhost.d/default.conf

	echo "upstream php5-fpm-sock {
		server unix:/var/run/php5-fpm.sock;
	}" > /etc/nginx/conf.d/php.conf

fi


#Install PHP-FPM and make it listen on a UNIX socket instead of TCP.
if [ "${OS}" == "ubuntu" ]
then
	apt-get -y install php5-fpm
	sed -i 's_listen\ =\ .*_listen = /var/run/php5-fpm.sock_' /etc/php5/fpm/pool.d/www.conf
fi

