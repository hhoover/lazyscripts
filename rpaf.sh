#!/bin/bash
## mod_rpaf Lazy Script
## Author: David Wittman <david@wittman.com>

SOURCE="http://c432251.r51.cf2.rackcdn.com/mod_rpaf-0.6-2.x86_64"
BASENAME=$(basename ${SOURCE})
# Set configuration path (relative to default Apache directory)
CONFIGFILE="conf.d/mod_rpaf.conf"
TEMPDIR="/tmp"

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

pass() {
    COLUMNS=$(tput cols)
    echo $1 | awk -v width=${COLUMNS} '{ padding=(width-length($0)-8); printf "%"(padding)"s", "[  ";}'
    echo -e "${green}OK${normal}  ]"
}

# Usage: /path/to/command || die "This shit didn't work"
die() {
    COLUMNS=$(tput cols)
    echo $1 | awk -v width=${COLUMNS} '{ padding=(width-length($0)-8); printf "%"(padding)"s", "[ ";}'
    echo -e "${bold}${red}FAIL${normal} ]"
    exit 1
}

get_distro() {
if [ "$distro" == "Ubuntu" ]; then
	EXT=".deb"
	APACHE="apache2"
elif [ "$distro" == "Redhat/CentOS" ]; then
	EXT=".rpm"
	APACHE="httpd"
else
    echo "Unable to detect distribution."
	exit 1
fi
}

reload_apache() {
	/etc/init.d/${APACHE} reload > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "${red}Error${normal} detected upon Apache reload. Moving config file to ${CONFIGFILE}.old"
		mv /etc/${APACHE}/${CONFIGFILE}{,.old}
		/etc/init.d/${APACHE} reload
		exit 1
	fi
}

guess_lb() {
	if [ ! -d /var/log/${APACHE} ]; then
		return
	fi
	LB_GUESS=$(awk '/^10\.18[23]\.[^\s]*/ { print $1; exit }' /var/log/${APACHE}/*access?log)
	LB_GUESS=${LB_GUESS:-""}
}

get_distro
echo "${bold}${distro}${normal} detected."

guess_lb
read -p "Enter the load balancer's internal IP address: [${LB_GUESS}] " -e LBIP
# Set LBIP to default if empty
LBIP=${LBIP:-${LB_GUESS}}

# Download and install mod_rpaf
OUTPUT="Downloading ${BASENAME}..."
printf "$OUTPUT"
/usr/bin/wget --quiet -P ${TEMPDIR} ${SOURCE}${EXT} 
pass "$OUTPUT"

# Install package
OUTPUT="Installing package..."
printf "$OUTPUT"
if [ "$distro" == "Ubuntu" ]; then
	dpkg -i ${TEMPDIR}/${BASENAME}${EXT} > /dev/null 2>&1 || die "$OUTPUT"
elif [ "$distro" == "Redhat/CentOS" ]; then
	rpm -Uvh ${TEMPDIR}/${BASENAME}${EXT} > /dev/null 2>&1 || die "$OUTPUT"
fi
pass "$OUTPUT"

# Post-install stuff
OUTPUT="Creating configuration files..."
printf "$OUTPUT"
cat > /etc/${APACHE}/${CONFIGFILE} <<EOF
LoadModule rpaf_module /usr/lib64/httpd/modules/mod_rpaf-2.0.so

<IfModule mod_rpaf-2.0.c>
	RPAFenable On
	RPAFsethostname On
	# RPAFproxy_ips:	
	#	List of load balancer/proxy IP addresses (space delimited) 
	RPAFproxy_ips 127.0.0.1 ${LBIP}
	# RPAFheader: 	
	#	Header from which to pull client IP, commonly X-Forwarded-For
	RPAFheader X-Cluster-Client-Ip
</IfModule>
EOF
pass "$OUTPUT"

# Reload Apache
echo "Reloading Apache..."
reload_apache

echo
echo "Ding! Fries are done."

