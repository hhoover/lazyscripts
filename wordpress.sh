#!/bin/bash
# Installs Wordpress for a new domain
# usage ./wordpress.sh

# Get some information and set variables
function get_domain() {
	read -p "Please enter the domain name (no www): " domain
	read -p "Please enter desired SFTP username: " username
	read -p "Please enter the 10.x.x.x address of your DB Server (or use localhost): " dbhost
	read -p "Please enter desired MySQL database name: " database
	read -p "Please enter desired MySQL username: " db_user
	web_password=$( apg -m 7 -n 1 )
	db_password=$( apg -m 7 -n 1 )
	eth1ip=$( ifconfig eth1 | grep 'inet addr:'| cut -d: -f2 | awk '{ print $1}' )
}

# add a virtual host and restart Apache
function configure_apache() {
	if [[ $distro = "Redhat/CentOS" ]]; then
		cat > /etc/httpd/vhost.d/$domain.conf <<-EOF
		<VirtualHost *:80>
		ServerName $domain
		ServerAlias www.$domain
		DocumentRoot /var/www/vhosts/$domain/wordpress
		<Directory /var/www/vhosts/$domain/wordpress>
		AllowOverride All
		</Directory>
		CustomLog logs/$domain-access_log common
		ErrorLog logs/$domain-error_log
		</VirtualHost>
		EOF
		service httpd restart > /dev/null 2>&1
	elif [[ $distro = "Ubuntu" ]]; then
		cat > /etc/apache2/sites-available/$domain <<-EOF
		<VirtualHost *:80>
		ServerName $domain
		ServerAlias www.$domain
		DocumentRoot /var/www/vhosts/$domain/wordpress
		<Directory /var/www/vhosts/$domain/wordpress>
		AllowOverride All
		</Directory>
		CustomLog /var/log/apache2/$domain-access_log common
		ErrorLog /var/log/apache2/$domain-error_log
		</VirtualHost>
		EOF
		a2ensite $domain > /dev/null 2>&1
		service apache2 restart	 > /dev/null 2>&1
fi
}

# Fetch Wordpress and extract it
# make a document root
function get_wordpress() {
	cd /root
	wget -q http://wordpress.org/latest.tar.gz
	mkdir -p /var/www/vhosts/$domain
	tar -C /var/www/vhosts/$domain -xzf latest.tar.gz
	rm -f /root/latest.tar.gz
	useradd -d /var/www/vhosts/$domain $username > /dev/null 2>&1
	echo $web_password | passwd $username --stdin > /dev/null 2>&1
}

# Set up a database locally OR show the commands to run
function configure_mysql() {
	MYSQL=$( which mysql )
	CREATE_DB="CREATE DATABASE ${database};"
	CREATE_DB_LOCAL_USER="GRANT ALL PRIVILEGES ON ${database}.* TO '${db_user}'@'${dbhost}' IDENTIFIED BY '${db_password}';"
	CREATE_DB_REMOTE_USER="GRANT ALL PRIVILEGES ON ${database}.* TO '${db_user}'@'${eth1ip}' IDENTIFIED BY '${db_password}';"
	FP="FLUSH PRIVILEGES;"
	SQL="${CREATE_DB}${CREATE_DB_LOCAL_USER}${FP}"
	if [[ $dbhost == "localhost" ]]; then
		$MYSQL -e "$SQL"
		echo "The MySQL database credentials are: "
		echo "User: ${db_user}"
		echo "Password: ${db_password}"
	else
		echo "Run these commands on your database server: "
		echo $CREATE_DB
		echo $CREATE_DB_REMOTE_USER
		echo $FP
	fi
}

# make wp-config.php and protect it
function create_wp_config() {
	cd /var/www/vhosts/$domain/wordpress
	keys=$( curl -s -k https://api.wordpress.org/secret-key/1.1/salt )
	cat > wp-config.php <<-EOF
	<?php
	define('DB_NAME', '${database}');
	define('DB_USER', '${db_user}');
	define('DB_PASSWORD', '${db_password}');
	define('DB_HOST', '${dbhost}');
	define('DB_CHARSET', 'utf8');
	define('DB_COLLATE', '');
	$keys
	\$table_prefix  = 'wp_';
	define('WPLANG', '');
	define('WP_DEBUG', false);
	if ( !defined('ABSPATH') )
	        define('ABSPATH', dirname(__FILE__) . '/');
			require_once(ABSPATH . 'wp-settings.php');
	EOF
    cat > .htaccess <<-EOF
	<files wp-config.php>
	order allow,deny
	deny from all
	</files>
	EOF
	chown -R $username: /var/www/vhosts/$domain
}

get_domain
echo "Beginning Wordpress installation."
get_wordpress
echo "Wordpress has been installed in /var/www/vhosts/${domain}/wordpress."
create_wp_config
configure_apache
echo "Apache has been configured for ${domain} and restarted."
echo "The SFTP credentials are: "
echo "User: ${username}"
echo "Password: ${web_password}"
configure_mysql
echo "I like salsa!"
exit 0