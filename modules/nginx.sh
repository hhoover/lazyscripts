#!/bin/bash
# Installs Nginx as a webserver with php-fpm
# Author: James Dewey


#Check for OS and set needed stuff:

if [ ! -a /etc/redhat-release ]	 && [ "$(lsb_release -d 2>/dev/null| awk '{print $2}')" == "Ubuntu" ]
then
	OS=ubuntu
elif [ ! -a /etc/redhat-release ] && [ "$(lsb_release -r 2>/dev/null| awk '{print $2}')" == "10.04" ]
then
	echo "Nginx Installer is not supported on ubuntu 10.04 due to not having PHP-FPM available in the repo."
	exit 0
elif [ -a /etc/redhat-release ] && [ "$(awk '{print $1}' /etc/redhat-release)" == "CentOS" ]
then
	if [[ "$(awk '{print $3}' /etc/redhat-release)" =~ 5. ]]
	then
		OS=cent5
	elif [[ "$(awk '{print $4}' /etc/redhat-release)" =~ 6. ]]
	then
		OS=cent6
	fi
elif [ -a /etc/redhat-release ] && [ "$(awk '{print $1 $2}' /etc/redhat-release)" == "RedHat" ]
then
        if [[ "$(awk '{print $7}' /etc/redhat-release)" =~ 5. ]]
        then
                OS=rh5
        elif [[ "$(awk '{print $7}' /etc/redhat-release)" =~ 6. ]]
        then
                OS=rh6
        fi

else
	echo "Unsupported OS detected, this script will now exit."
	exit 0
fi



#Check for Repo
check_repo() 
{
	if [[ "${OS}" == "ubuntu" ]]
	then
		if [[ -z "$(grep -Ri "nginx" /etc/apt/)" ]]
		then
			REPOEXISTS=0
		else
			REPOEXISTS=1
		fi
	elif [[ "${OS}" == "cent5" ]]
	then
		if [[ -z "$(grep -Ri "nginx" /etc/yum.repos.d)" ]]
		then
			REPOEXISTS=0
		else
			REPOEXISTS=1
		fi
	elif [[ "${OS}" == "cent6" ]]
        then
		if [[ -z "$(grep -Ri "nginx" /etc/yum.repos.d)" ]]
		then
			REPOEXISTS=0
		else
			REPOEXISTS=1
		fi
	elif [[ "${OS}" == "rh5" ]]
        then
                if [[ -z "$(grep -Ri "nginx" /etc/yum.repos.d)" ]]
                then
                        REPOEXISTS=0
                else
                        REPOEXISTS=1
                fi
	elif [[ "${OS}" == "rh6" ]]
        then
                if [[ -z "$(grep -Ri "nginx" /etc/yum.repos.d)" ]]
                then
                        REPOEXISTS=0
                else
                        REPOEXISTS=1
                fi
	fi
}



# Set up Repo
create_repo() {
	if [ "${OS}" == "ubuntu" ]
	then
		echo -e "\n\n# Nginx Repo" >> /etc/apt/sources.list
		echo "deb http://nginx.org/packages/ubuntu/ lucid nginx" >> /etc/apt/sources.list
		echo "deb-src http://nginx.org/packages/ubuntu/ lucid nginx" >> /etc/apt/sources.list
	elif [ "${OS}" == "cent5" ]
	then
		echo '[nginx]' >> /etc/yum.repos.d/nginx.repo
		echo 'name=nginx repo' >> /etc/yum.repos.d/nginx.repo
		echo 'baseurl=http://nginx.org/packages/centos/5/$basearch/' >> /etc/yum.repos.d/nginx.repo
		echo 'gpgcheck=0' >> /etc/yum.repos.d/nginx.repo
		echo 'enabled=1' >> /etc/yum.repos.d/nginx.repo
	elif [ "${OS}" == "cent6" ]
        then
                echo '[nginx]' >> /etc/yum.repos.d/nginx.repo
                echo 'name=nginx repo' >> /etc/yum.repos.d/nginx.repo
                echo 'baseurl=http://nginx.org/packages/centos/6/$basearch/' >> /etc/yum.repos.d/nginx.repo
                echo 'gpgcheck=0' >> /etc/yum.repos.d/nginx.repo
                echo 'enabled=1' >> /etc/yum.repos.d/nginx.repo
	elif [ "${OS}" == "rh5" ]
        then
                echo '[nginx]' >> /etc/yum.repos.d/nginx.repo
                echo 'name=nginx repo' >> /etc/yum.repos.d/nginx.repo
                echo 'baseurl=http://nginx.org/packages/rhel/5/$basearch/' >> /etc/yum.repos.d/nginx.repo
                echo 'gpgcheck=0' >> /etc/yum.repos.d/nginx.repo
                echo 'enabled=1' >> /etc/yum.repos.d/nginx.repo
        elif [ "${OS}" == "rh6" ]
        then
                echo '[nginx]' >> /etc/yum.repos.d/nginx.repo
                echo 'name=nginx repo' >> /etc/yum.repos.d/nginx.repo
                echo 'baseurl=http://nginx.org/packages/rhel/6/$basearch/' >> /etc/yum.repos.d/nginx.repo
                echo 'gpgcheck=0' >> /etc/yum.repos.d/nginx.repo
                echo 'enabled=1' >> /etc/yum.repos.d/nginx.repo

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
	monit stop apache > /dev/null 2>&1
	monit unmonitor apache > /dev/null 2>&1
	service apache2 stop > /dev/null 2>&1
	update-rc.d apache2 disable > /dev/null 2>&1
elif [ "${OS}" == "cent5" ]
then
	echo "Stopping Apache and disabling it on boot.."
	monit stop apache > /dev/null 2>&1
        monit unmonitor apache > /dev/null 2>&1
	service httpd stop > /dev/null 2>&1
	chkconfig httpd off > /dev/null 2>&1
elif [ "${OS}" == "cent6" ]
then
        echo "Stopping Apache and disabling it on boot.."
	monit stop apache > /dev/null 2>&1
        monit unmonitor apache > /dev/null 2>&1
        service httpd stop > /dev/null 2>&1
        chkconfig httpd off > /dev/null 2>&1
elif [ "${OS}" == "rh5" ]
then
        echo "Stopping Apache and disabling it on boot.."
	monit stop apache > /dev/null 2>&1
        monit unmonitor apache > /dev/null 2>&1
        service httpd stop > /dev/null 2>&1
        chkconfig httpd off > /dev/null 2>&1
elif [ "${OS}" == "rh6" ]
then
        echo "Stopping Apache and disabling it on boot.."
	monit stop apache > /dev/null 2>&1
        monit unmonitor apache > /dev/null 2>&1
        service httpd stop > /dev/null 2>&1
        chkconfig httpd off > /dev/null 2>&1
fi

#Check for if  Nginx is installed
if [ "${OS}" == "ubuntu" ]
then
	echo "Checking for existing nginx installation..."
	if [ -z "$(dpkg -l | grep -i nginx)" ]
	then
		NGINXINSTALLED=0
	else	
 		echo "Nginx is already installed, remove it and try the installation again."
		exit 0
	fi
elif [ "${OS}" == "cent5" ]
then
	echo "Checking for existing nginx installation..."
	if [ -z "$(rpm -qa | grep -i nginx)" ]
	then
		NGINXINSTALLED=0
	else
		echo "Nginx is already installed, remove it and try the installation again."
                exit 0
	fi
elif [ "${OS}" == "cent6" ]
then
        echo "Checking for existing nginx installation..."
        if [ -z "$(rpm -qa | grep -i nginx)" ]
        then
                NGINXINSTALLED=0
        else
                echo "Nginx is already installed, remove it and try the installation again."
                exit 0
        fi
elif [ "${OS}" == "rh5" ]
then
        echo "Checking for existing nginx installation..."
        if [ -z "$(rpm -qa | grep -i nginx)" ]
        then
                NGINXINSTALLED=0
        else
                echo "Nginx is already installed, remove it and try the installation again."
                exit 0
        fi
elif [ "${OS}" == "rh6" ]
then
        echo "Checking for existing nginx installation..."
        if [ -z "$(rpm -qa | grep -i nginx)" ]
        then
                NGINXINSTALLED=0
        else
                echo "Nginx is already installed, remove it and try the installation again."
                exit 0
        fi

fi


#Install Nginx
if [ "${OS}" == "ubuntu" ] && [ "${NGINXINSTALLED}" == 0 ]
then
	echo "Installing Nginx..."

	gpg --keyserver pgpkeys.mit.edu --recv-key  ABF5BD827BD9BF62 > /dev/null 2>&1
	gpg -a --export ABF5BD827BD9BF62 | sudo apt-key add - > /dev/null 2>&1
	apt-get  update > /dev/null 2>&1
	apt-get -y install nginx > /dev/null 2>&1
elif [ "${OS}" == "cent5" ] && [ "${NGINXINSTALLED}" == 0 ]
then
	echo "Installing Nginx..."
	yum -y install nginx > /dev/null 2>&1
elif [ "${OS}" == "cent6" ] && [ "${NGINXINSTALLED}" == 0 ]
then
        echo "Installing Nginx..."
        yum -y install nginx > /dev/null 2>&1
elif [ "${OS}" == "rh5" ] && [ "${NGINXINSTALLED}" == 0 ]
then
        echo "Installing Nginx..."
        yum -y install nginx > /dev/null 2>&1
elif [ "${OS}" == "rh6" ] && [ "${NGINXINSTALLED}" == 0 ]
then
        echo "Installing Nginx..."
        yum -y install nginx > /dev/null 2>&1


fi



#Set up nginx configurations for vhosts + default vhost + php-fpm
mkdir /var/www/vhosts/ > /dev/null 2>&1
mkdir /var/www/vhosts/default > /dev/null 2>&1
mkdir /etc/nginx/vhost.d > /dev/null 2>&1
sed -e '$d' /etc/nginx/nginx.conf > /tmp/nginx.conf
cat /tmp/nginx.conf > /etc/nginx.conf
echo -e "include /etc/nginx/vhost.d/*.conf;\n }" >> /etc/nginx.conf
rm -rf /tmp/nginx.conf
echo 'server {
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

}' > /etc/nginx/vhost.d/default.conf


echo 'server {
	listen 80;

	#Uncomment this to make it bind to a specific IP/port (Such as for SSL)
	#listen 12.34.56.78:443;

	#Comment this out if you uncomment server_name below
	server_name www.example.com example.com;

	#Uncomment the first line for www->nonwww redirects, the second one for nonwww->www redirects
	#server_name example.com;
	#server_name www.example.com;

	#Uncomment this for SSL support
	#ssl on;
	#ssl_certificate /path/to/cert;
	#ssl_certificate_key /path/to/key;
	#ssl_client_certificate /path/to/CAcert;


	access_log /var/log/nginx/example.com.access.log;
	error_log /var/log/nginx/example.com.error.log error;

	location / {
		root /var/www/vhosts/example.com;
		index index.php index.html index.html;
	}

	location ~\.php$ {
		fastcgi_pass   php5-fpm-sock;
		fastcgi_index  index.php;
		fastcgi_param  SCRIPT_FILENAME  /var/www/vhosts/example.com$fastcgi_script_name;
		include fastcgi_params;
	}
	
	#Comment this out to rewrite www to non-www.
	#server {
	#listen 80;
	#server_name www.example.com;
	#rewrite ^ http://example.com$request_uri? permanent;
	#}
	
	#Comment this out to rewrite nonwww to www.
	#server {
	#listen 80;
	#server_name example.com
	#rewrite ^ http://www.example.com$request_uri? permanent;
	#}' > /etc/nginx/vhost.d/default.template


	
	

echo "upstream php5-fpm-sock {
	server unix:/var/run/php5-fpm.sock;
}" > /etc/nginx/conf.d/php.conf



#Check that php-fpm isn't alreadu installed
echo "Checking for current PHP-FPM..."
if [[ "${OS}" == "ubuntu" ]] 
then
	if [[ -z "$(dpkg -l | grep -i php-fpm)" ]]
	then
		FPMINSTALLED=0
	else
		FPMINSTALLED=1
	fi
elif [[ "${OS}" == "cent5" ]]
then
	if [[ -z "$(rpm -qa | grep php53u-fpm)" ]]
	then
		FPMINSTALLED=0
	else
		FPMINSTALLED=1
	fi
elif [[ "${OS}" == "cent6" ]]
then
        if [[ -z "$(rpm -qa | grep php53u-fpm)" ]]
        then
                FPMINSTALLED=0
        else
                FPMINSTALLED=1
        fi
elif [[ "${OS}" == "rh5" ]]
then
        if [[ -z "$(rpm -qa | grep php53u-fpm)" ]]
        then
                FPMINSTALLED=0
        else
                FPMINSTALLED=1
        fi
elif [[ "${OS}" == "rh6" ]]
then
        if [[ -z "$(rpm -qa | grep php53u-fpm)" ]]
        then
                FPMINSTALLED=0
        else
                FPMINSTALLED=1
        fi

fi



#Install PHP-FPM and make it listen on a UNIX socket instead of TCP.
echo "Setting up PHP-FPM..."
if [[ "${OS}" == "ubuntu" ]]
then
	if [[ "${FPMINSTALLED}" == 0 ]]
	then
		apt-get -y install php5-fpm  > /dev/null 2>&1
	fi
	sed -i 's_listen\ =\ .*_listen = /var/run/php5-fpm.sock_' /etc/php5/fpm/pool.d/www.conf
elif [[ "${OS}" == "cent5" ]]
then
	if [[ "${FPMINSTALLED}" == 0 ]]
	then
		yum -y install php53u-fpm > /dev/null 2>&1
	fi
	sed -i 's_listen\ =\ .*_listen = /var/run/php5-fpm.sock_' /etc/php-fpm.d/www.conf
elif [[ "${OS}" == "cent6" ]]
then
        if [[ "${FPMINSTALLED}" == 0 ]]
        then
		#We need to remove old php, as it doesn't have FPM, and install php53u.
		yum -y remove php php-* > /dev/null 2>&1 
                yum -y install php53u-fpm php53u-suhosin php53u-pear php53u-pecl-apc php53u-pdo php53u-xml php53u-gd php53u-mbstring php53u-mcrypt php53u-mysql > /dev/null 2>&1
        fi
        sed -i 's_listen\ =\ .*_listen = /var/run/php5-fpm.sock_' /etc/php-fpm.d/www.conf
elif [[ "${OS}" == "rh5" ]]
then
        if [[ "${FPMINSTALLED}" == 0 ]]
        then
                yum -y install php53u-fpm > /dev/null 2>&1
        fi
        sed -i 's_listen\ =\ .*_listen = /var/run/php5-fpm.sock_' /etc/php-fpm.d/www.conf
elif [[ "${OS}" == "rh6" ]]
then
        if [[ "${FPMINSTALLED}" == 0 ]]
        then
                #We need to remove old php, as it doesn't have FPM, and install php53u.
                yum -y remove php php-* > /dev/null 2>&1
                yum -y install php53u-fpm php53u-suhosin php53u-pear php53u-pecl-apc php53u-pdo php53u-xml php53u-gd php53u-mbstring php53u-mcrypt php53u-mysql > /dev/null 2>&1
        fi
        sed -i 's_listen\ =\ .*_listen = /var/run/php5-fpm.sock_' /etc/php-fpm.d/www.conf


fi

#Start things and set to start on boot.
echo "Making it start on boot, and starting services..."
if [ "${OS}" == "ubuntu" ]
then
	service nginx restart > /dev/null 2>&1
	service php5-fpm restart > /dev/null 2>&1
	update-rc.d nginx enable > /dev/null 2>&1
	update-rc.d php5-fpm enable > /dev/null 2>&1
elif [ "${OS}" == "cent5" ]
then
	service nginx restart > /dev/null 2>&1
	service php-fpm restart > /dev/null 2>&1
	chkconfig nginx on > /dev/null 2>&1
	chkconfig php-fpm on > /dev/null 2>&1
elif [ "${OS}" == "cent6" ]
then
        service nginx restart > /dev/null 2>&1
        service php-fpm restart > /dev/null 2>&1
        chkconfig nginx on > /dev/null 2>&1
        chkconfig php-fpm on > /dev/null 2>&1
elif [ "${OS}" == "rh5" ]
then
        service nginx restart > /dev/null 2>&1
        service php-fpm restart > /dev/null 2>&1
        chkconfig nginx on > /dev/null 2>&1
        chkconfig php-fpm on > /dev/null 2>&1
elif [ "${OS}" == "rh6" ]
then
        service nginx restart > /dev/null 2>&1
        service php-fpm restart > /dev/null 2>&1
        chkconfig nginx on > /dev/null 2>&1
        chkconfig php-fpm on > /dev/null 2>&1

fi
echo "Nginx and PHP-FPM setup complete."