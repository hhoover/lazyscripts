#!/bin/bash
# Installs Drupal 7 for a new domain
# usage ./drupal.sh

# Get some information and set variables
function get_domain() {
	read -p "Please enter the domain name (no www): " domain
	read -p "Please enter desired SFTP username: " username
	read -p "Please enter the 10.x.x.x address of your DB Server (or use localhost): " dbhost
	read -p "Please enter desired MySQL database name: " database
	read -p "Please enter desired MySQL username: " db_user
	#web_password=$( apg -m 7 -n 1 )
	db_password=$( apg -m 7 -n 1 )
	db_password=${db_password/\'/\\\'}
	eth1ip=$( ifconfig eth1 | grep 'inet addr:'| cut -d: -f2 | awk '{ print $1}' )
}

# add a virtual host and restart Apache
function configure_apache() {
	if [[ $distro = "Redhat/CentOS" ]]; then
		cat > /etc/httpd/vhost.d/"${domain}.conf" <<-EOF
		<VirtualHost *:80>
			ServerName $domain
			ServerAlias www.$domain
			DocumentRoot /var/www/vhosts/$domain/public_html
			<Directory /var/www/vhosts/$domain/public_html>
				AllowOverride All
			</Directory>
			CustomLog logs/$domain-access_log common
			ErrorLog logs/$domain-error_log
		</VirtualHost>


		# <VirtualHost _default_:443>
		# ServerName $domain
		# DocumentRoot /var/www/vhosts/$domain/public_html
		# <Directory /var/www/vhosts/$domain/public_html>
		#	AllowOverride All
		# </Directory>

		# CustomLog /var/log/httpd/$domain-ssl-access.log combined
		# ErrorLog /var/log/httpd/$domain-ssl-error.log

		# # Possible values include: debug, info, notice, warn, error, crit,
		# # alert, emerg.
		# LogLevel warn

		# SSLEngine on
		# SSLCertificateFile    /etc/pki/tls/certs/$domain.crt
		# SSLCertificateKeyFile /etc/pki/tls/private/$domain.key
		# SSLCertificateChainFile /etc/pki/tls/certs/CA.crt

		# <FilesMatch "\.(cgi|shtml|phtml|php)$">
		# 	SSLOptions +StdEnvVars
		# </FilesMatch>

		# BrowserMatch "MSIE [2-6]" \\
		#	nokeepalive ssl-unclean-shutdown \\
		#	downgrade-1.0 force-response-1.0
		# BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
		# </VirtualHost>
EOF
		service httpd restart > /dev/null 2>&1
	elif [[ $distro = "Ubuntu" ]]; then
		cat > /etc/apache2/sites-available/"${domain}" <<-EOF
		<VirtualHost *:80>
			ServerName $domain
			ServerAlias www.$domain
			DocumentRoot /var/www/vhosts/$domain/public_html
			<Directory /var/www/vhosts/$domain/public_html>
				AllowOverride All
			</Directory>
			CustomLog /var/log/apache2/$domain-access_log common
			ErrorLog /var/log/apache2/$domain-error_log
		</VirtualHost>


		# <VirtualHost _default_:443>
		# ServerName $domain
		# DocumentRoot /var/www/vhosts/$domain/public_html
		# <Directory /var/www/vhosts/$domain/public_html>
		#	AllowOverride All
		# </Directory>

		# CustomLog /var/log/httpd/$domain-ssl-access.log combined
		# ErrorLog /var/log/httpd/$domain-ssl-error.log

		# # Possible values include: debug, info, notice, warn, error, crit,
		# # alert, emerg.
		# LogLevel warn

		# SSLEngine on
		# SSLCertificateFile    /etc/ssl/certs/$domain.pem
		# SSLCertificateKeyFile /etc/ssl/private/$domain.key
		# SSLCertificateChainFile /etc/ssl/certs/ca.crt

		# <FilesMatch "\.(cgi|shtml|phtml|php)$">
		# 	SSLOptions +StdEnvVars
		# </FilesMatch>

		# BrowserMatch "MSIE [2-6]" \\
		#	nokeepalive ssl-unclean-shutdown \\
		#	downgrade-1.0 force-response-1.0
		# BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
		# </VirtualHost>
EOF
		a2ensite $domain > /dev/null 2>&1
		service apache2 restart	 > /dev/null 2>&1
fi
}

# Fetch Drupal 7 and extract it
# make a document root
function get_drupal() {
	cd /root
	wget -q http://ftp.drupal.org/files/projects/drupal-7.14.tar.gz
	mkdir -p /var/www/vhosts/$domain/public_html
	tar -C /var/www/vhosts/$domain/ -xzf drupal-7.14.tar.gz
	rm -f /root/drupal-7.14.tar.gz
	useradd -d /var/www/vhosts/$domain $username > /dev/null 2>&1
	#echo $web_password | passwd $username --stdin > /dev/null 2>&1
}

# Set up a database locally OR show the commands to run
function configure_mysql() {
	MYSQL=$( which mysql )
	CREATE_DB="CREATE DATABASE IF NOT EXISTS ${database};"
	CREATE_DB_LOCAL_USER="GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON ${database}.* TO '${db_user}'@'${dbhost}' IDENTIFIED BY '${db_password}';"
	CREATE_DB_REMOTE_USER="GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON ${database}.* TO '${db_user}'@'${eth1ip}' IDENTIFIED BY '${db_password}';"
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

# make settings.php
function create_settings() {
	cd /var/www/vhosts/$domain/drupal-7.14/sites/default
	cat > settings.php <<-EOF
	<?php
	\$databases['default']['default'] = array(
		'driver' => 'mysql',
	 	'database' => '${database}',
	 	'username' => '${db_user}',
	 	'password' => '${db_password}',
	 	'host' => '${dbhost}',
		'prefix' => 'main_',
		'collation' => 'utf8_general_ci',
	);
	\$update_free_access = FALSE;
	\$drupal_hash_salt = '';
	ini_set('session.gc_probability', 1);
	ini_set('session.gc_divisor', 100);
	ini_set('session.gc_maxlifetime', 200000);
	ini_set('session.cookie_lifetime', 2000000);
	?>
	EOF
	chmod 666 /var/www/vhosts/$domain/drupal-7.14/sites/default/settings.php
	chown -R $username: /var/www/vhosts/$domain
}

get_domain
echo "Beginning Drupal 7 installation."
get_drupal
echo "Drupal has been installed in /var/www/vhosts/${domain}/public_html."
create_settings
configure_apache
echo "Apache has been configured for ${domain} and restarted."
echo "The SFTP credentials are: "
echo "User: ${username}"
#echo "Password: ${web_password}"
echo -e "\e[0;31m*** Please Set A SFTP Password ***\e[0m" 
configure_mysql
mv /var/www/vhosts/$domain/drupal-7.14 /var/www/vhosts/$domain/public_html
#Dirty Move
echo "I like salsa!"
exit 0
