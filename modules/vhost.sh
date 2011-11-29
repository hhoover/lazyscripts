#!/bin/bash
# Virtual Host maker
# Usage: lsvhost [-s] -d domain.com

function SSLcheck() {
	SSL="off"
	OPTSTRING=sd:
	while getopts ${OPTSTRING} OPTION; do
		case $OPTION in
			s) SSL="on" ;;
			d) domain=$OPTARG ;;
			*) echo "Usage: lsvhost [-s] -d domain.com"
				return 1 ;;
		esac
	done
	
	if [[ $SSL = "off" ]]; then
		noSSL
	elif [[ $SSL = "on" ]]; then
		sslvhost
	else
		echo "Something went wrong. Oops."
		return 1
	fi
} 

function noSSL() {
	if [[ -z ${domain} ]]; then
		echo "Usage: lsvhost [-s] -d domain.com"
		return 1
	fi
	
	if [[ $distro = "Redhat/CentOS" ]]; then
		cat > /etc/httpd/vhost.d/$domain.conf <<-EOF
		<VirtualHost *:80>
			ServerName $domain
			ServerAlias www.$domain
			DocumentRoot /var/www/vhosts/$domain
			<Directory /var/www/vhosts/$domain>
				AllowOverride All
			</Directory>
			CustomLog logs/$domain-access_log common
			ErrorLog logs/$domain-error_log
		</VirtualHost>


		# <VirtualHost _default_:443>
		# ServerName $domain
		# DocumentRoot /var/www/vhosts/$domain
		# <Directory /var/www/vhosts/$domain>
		#	AllowOverride All
		# </Directory>

		# CustomLog /var/log/httpd/$domain-ssl-access.log combined
		# ErrorLog /var/log/httpd/$domain-ssl-error.log

		# # Possible values include: debug, info, notice, warn, error, crit,
		# # alert, emerg.
		# LogLevel warn

		# SSLEngine on
		# SSLCertificateFile    /etc/pki/tls/certs/localhost.crt
		# SSLCertificateKeyFile /etc/pki/tls/private/localhost.key

		# <FilesMatch "\.(cgi|shtml|phtml|php)$">
		# 	SSLOptions +StdEnvVars
		# </FilesMatch>

		# BrowserMatch "MSIE [2-6]" \\
		#	nokeepalive ssl-unclean-shutdown \\
		#	downgrade-1.0 force-response-1.0
		# BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
		# </VirtualHost>
		EOF

		mkdir -p /var/www/vhosts/$domain
		service httpd restart > /dev/null 2>&1

	elif [[ $distro = "Ubuntu" ]]; then
		cat > /etc/apache2/sites-available/$domain <<-EOF
		<VirtualHost *:80>
			ServerName $domain
			ServerAlias www.$domain
			DocumentRoot /var/www/vhosts/$domain
			<Directory /var/www/vhosts/$domain>
				AllowOverride All
			</Directory>
			CustomLog /var/log/apache2/$domain-access_log common
			ErrorLog /var/log/apache2/$domain-error_log
		</VirtualHost>


		# <VirtualHost _default_:443>
		# ServerName $domain
		# DocumentRoot /var/www/vhosts/$domain
		# <Directory /var/www/vhosts/$domain>
		#	AllowOverride All
		# </Directory>

		# CustomLog /var/log/httpd/$domain-ssl-access.log combined
		# ErrorLog /var/log/httpd/$domain-ssl-error.log

		# # Possible values include: debug, info, notice, warn, error, crit,
		# # alert, emerg.
		# LogLevel warn

		# SSLEngine on
		# SSLCertificateFile    /etc/pki/tls/certs/localhost.crt
		# SSLCertificateKeyFile /etc/pki/tls/private/localhost.key

		# <FilesMatch "\.(cgi|shtml|phtml|php)$">
		# 	SSLOptions +StdEnvVars
		# </FilesMatch>

		# BrowserMatch "MSIE [2-6]" \\
		#	nokeepalive ssl-unclean-shutdown \\
		#	downgrade-1.0 force-response-1.0
		# BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
		# </VirtualHost>
		EOF

		mkdir -p /var/www/vhosts/$domain
		a2ensite $domain > /dev/null 2>&1
		service apache2 restart	 > /dev/null 2>&1
	else
		echo "Unsupported OS"
	fi
}

function sslvhost() {
	if [[ -z ${domain} ]]; then
		echo "Usage: lsvhost [-s] -d domain.com"
		return 1
	fi
read -p "Please enter the path to the key: " key
read -p "Please enter the path to the cert: " cert
read -p "Please enter the path to the bundle: " bundle
showips
read -p "Please enter the IP you wish to use: " ip

		if [[ $distro = "Redhat/CentOS" ]]; then
			cat > /etc/httpd/vhost.d/$domain.conf <<-EOF
			<VirtualHost *:80>
				ServerName $domain
				ServerAlias www.$domain
				DocumentRoot /var/www/vhosts/$domain
				<Directory /var/www/vhosts/$domain>
					AllowOverride All
				</Directory>
				CustomLog logs/$domain-access_log common
				ErrorLog logs/$domain-error_log
			</VirtualHost>


			 <VirtualHost $ip:443>
			 ServerName $domain
			 DocumentRoot /var/www/vhosts/$domain
			 <Directory /var/www/vhosts/$domain>
				AllowOverride All
			 </Directory>

			 CustomLog /var/log/httpd/$domain-ssl-access.log combined
			 ErrorLog /var/log/httpd/$domain-ssl-error.log

			 # Possible values include: debug, info, notice, warn, error, crit,
			 # alert, emerg.
			 LogLevel warn

			 SSLEngine on
			 SSLCertificateFile    $cert
			 SSLCertificateKeyFile $key
			 SSLCertificateChainFile $bundle

			 <FilesMatch "\.(cgi|shtml|phtml|php)$">
			 	SSLOptions +StdEnvVars
			 </FilesMatch>

			 BrowserMatch "MSIE [2-6]" \\
				nokeepalive ssl-unclean-shutdown \\
				downgrade-1.0 force-response-1.0
			 BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
			 </VirtualHost>
			EOF

			mkdir -p /var/www/vhosts/$domain
			service httpd restart > /dev/null 2>&1

		elif [[ $distro = "Ubuntu" ]]; then
			cat > /etc/apache2/sites-available/$domain <<-EOF
			<VirtualHost *:80>
				ServerName $domain
				ServerAlias www.$domain
				DocumentRoot /var/www/vhosts/$domain
				<Directory /var/www/vhosts/$domain>
					AllowOverride All
				</Directory>
				CustomLog /var/log/apache2/$domain-access_log common
				ErrorLog /var/log/apache2/$domain-error_log
			</VirtualHost>


			 <VirtualHost $ip:443>
			 ServerName $domain
			 DocumentRoot /var/www/vhosts/$domain
			 <Directory /var/www/vhosts/$domain>
				AllowOverride All
			 </Directory>

			 CustomLog /var/log/httpd/$domain-ssl-access.log combined
			 ErrorLog /var/log/httpd/$domain-ssl-error.log

			 # Possible values include: debug, info, notice, warn, error, crit,
			 # alert, emerg.
			 LogLevel warn

			 SSLEngine on
			 SSLCertificateFile    $cert
			 SSLCertificateKeyFile $key
			 SSLCertificateChainFile $bundle

			 <FilesMatch "\.(cgi|shtml|phtml|php)$">
			 	SSLOptions +StdEnvVars
			 </FilesMatch>

			 BrowserMatch "MSIE [2-6]" \\
				nokeepalive ssl-unclean-shutdown \\
				downgrade-1.0 force-response-1.0
			 BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
			 </VirtualHost>
			EOF

			mkdir -p /var/www/vhosts/$domain
			a2ensite $domain > /dev/null 2>&1
			service apache2 restart	 > /dev/null 2>&1
		else
			echo "Unsupported OS"
		fi
}

function showips() {
	/sbin/ifconfig | awk '/^eth/ { printf("%s\t",$1) } /inet addr:/ { gsub(/.*:/,"",$2); if ($2 !~ /^127/) print $2; }'
}

SSLcheck "$@"