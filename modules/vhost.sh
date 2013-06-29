#!/bin/bash
# Virtual Host maker

function usage() {
	cat <<-EOF
	Usage: lsvhost [-s] [-r /path/to/docroot] -d domain.com
	Options:
	-s = SSL
	-r = custom documentroot
	-d = your domain *REQUIRED*
	EOF
	return 1
}

function SSLcheck() {
	SSL=false
	OPTSTRING=sr:d:
	while getopts ${OPTSTRING} OPTION; do
		case $OPTION in
			s) SSL=true ;;
			r) DOCROOT="${OPTARG//[[:space:]]}";;
			d) domain="${OPTARG//[[:space:]]}";;
			*) usage ;;
		esac
	done

	if [[ -z ${domain} ]]; then
		usage
		return 1
	fi
	
	DEFAULT_DOCROOT="/var/www/vhosts/${domain}/public_html"
	DOCROOT=${DOCROOT:-${DEFAULT_DOCROOT}}
	
	
	$SSL && sslvhost || noSSL
} 

function noSSL() {
	if [[ $distro = "Redhat/CentOS" ]]; then
		cat > /etc/httpd/vhost.d/"${domain}".conf <<-EOF
		<VirtualHost *:80>
			ServerName $domain
			ServerAlias www.$domain
			DocumentRoot ${DOCROOT}
			<Directory ${DOCROOT}>
				AllowOverride All
			</Directory>
			CustomLog logs/$domain-access_log common
			ErrorLog logs/$domain-error_log
		</VirtualHost>


		# <VirtualHost _default_:443>
		# ServerName $domain
		# DocumentRoot ${DOCROOT}
		# <Directory ${DOCROOT}>
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

		mkdir -p ${DOCROOT}
		service httpd restart > /dev/null 2>&1

	elif [[ $distro = "Ubuntu" ]]; then
		cat > /etc/apache2/sites-available/"${domain}" <<-EOF
		<VirtualHost *:80>
			ServerName $domain
			ServerAlias www.$domain
			DocumentRoot ${DOCROOT}
			<Directory ${DOCROOT}>
				AllowOverride All
			</Directory>
			CustomLog /var/log/apache2/$domain-access_log common
			ErrorLog /var/log/apache2/$domain-error_log
		</VirtualHost>


		# <VirtualHost _default_:443>
		# ServerName $domain
		# DocumentRoot ${DOCROOT}
		# <Directory ${DOCROOT}>
		#	AllowOverride All
		# </Directory>

		# CustomLog /var/log/httpd/$domain-ssl-access.log combined
		# ErrorLog /var/log/httpd/$domain-ssl-error.log

		# # Possible values include: debug, info, notice, warn, error, crit,
		# # alert, emerg.
		# LogLevel warn

		# SSLEngine on
		# SSLCertificateFile    /etc/ssl/certs/ssl-cert-snakeoil.pem
		# SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
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

		mkdir -p ${DOCROOT}
		a2ensite $domain > /dev/null 2>&1
		service apache2 restart	 > /dev/null 2>&1
	else
		echo "Unsupported OS"
	fi
	return 0
}

function sslvhost() {
read -p "Please enter the path to the key: " key
read -p "Please enter the path to the cert: " cert
read -p "Please enter the path to the bundle: " bundle
showips
read -p "Please enter the IP you wish to use: " ip

		if [[ $distro = "Redhat/CentOS" ]]; then
			cat > /etc/httpd/vhost.d/"${domain}".conf <<-EOF
			<VirtualHost *:80>
				ServerName $domain
				ServerAlias www.$domain
				DocumentRoot ${DOCROOT}
				<Directory ${DOCROOT}>
					AllowOverride All
				</Directory>
				CustomLog logs/$domain-access_log common
				ErrorLog logs/$domain-error_log
			</VirtualHost>


			 <VirtualHost $ip:443>
			 ServerName $domain
			 DocumentRoot ${DOCROOT}
			 <Directory ${DOCROOT}>
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

			mkdir -p ${DOCROOT}
			service httpd restart > /dev/null 2>&1

		elif [[ $distro = "Ubuntu" ]]; then
			cat > /etc/apache2/sites-available/"${domain}" <<-EOF
			<VirtualHost *:80>
				ServerName $domain
				ServerAlias www.$domain
				DocumentRoot ${DOCROOT}
				<Directory ${DOCROOT}>
					AllowOverride All
				</Directory>
				CustomLog /var/log/apache2/$domain-access_log common
				ErrorLog /var/log/apache2/$domain-error_log
			</VirtualHost>


			 <VirtualHost $ip:443>
			 ServerName $domain
			 DocumentRoot ${DOCROOT}
			 <Directory ${DOCROOT}>
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

			mkdir -p ${DOCROOT}
			a2ensite $domain > /dev/null 2>&1
			service apache2 restart	 > /dev/null 2>&1
		else
			echo "Unsupported OS"
		fi
		return 0
}

function showips() {
	/sbin/ifconfig | awk '/^eth/ { printf("%s\t",$1) } /inet addr:/ { gsub(/.*:/,"",$2); if ($2 !~ /^127/) print $2; }'
}

SSLcheck "$@"
