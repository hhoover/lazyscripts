#!/bin/bash
# LazyScripts Initializer Script
# https://github.com/hhoover/lazyscripts/
#
# Usage: dot (`. ls-init.sh`) or source this file (`source ls-init.sh`)
#        to load into your current shell
#

LZS_VERSION=004
LZS_PREFIX=$(dirname $(readlink -f $BASH_SOURCE))
LZS_APP="$LZS_PREFIX/ls-init.sh"
LZS_URLPREFIX="git://github.com/hhoover/lazyscripts.git"
LZS_GETURL="$LZS_URLPREFIX/ls-init.sh"
LZS_MOD_PATH="${LZS_PREFIX}/modules/"

function isFunction() {
        declare -F $1 &> /dev/null
        return $?
}

# lz - Main function
function lz() {
	local ARG="$1"
	shift	# Push $1 off the arguments
        # Find files matching the parameter, limit 1
        local FILE=$(/bin/ls ${LZS_MOD_PATH}${ARG}.* 2> /dev/null | head -1)

	if ( isFunction ${ARG} ); then
		# Run the function
		${ARG} "$*"
	elif ( isFunction ls${ARG} ); then
		ls${ARG} "$*"
	elif [ -r "${FILE}" ]; then
		# Execute the module
		chmod +x ${FILE} && ${FILE} "$*"
	else
		return 1
	fi
}

# _lz - Tab completion function
function _lz() {
        local cur opts
        cur=${COMP_WORDS[COMP_CWORD]}
        # Append new functions here
        opts="ap apcheck apdocs approc cloudkick postfix vhost vsftpd"
        opts="${opts} lsync wordpress drupal webmin varnish concurchk"
        opts="${opts} crtchk rpaf pma nginx haproxy hppool nodejs mytuner"
        opts="${opts} rblcheck recap"
        COMPREPLY=( $(compgen -W "${opts}" -- $cur) )
}

function lscolors() { 
	# defines the available colors and makes them globally accessible
	black='\E[0;30m';
	red='\E[0;31m';
	green='\E[0;32m';
	yellow='\E[0;33m';
	blue='\E[0;34m';
	magenta='\E[0;35m';
	cyan='\E[0;36m';
	norm='\E[0m';
	gray='\E[1;30m';
	brightred='\E[1;31m';
	brightgreen='\E[1;32m';
	brightyellow='\E[1;33m';
	brightblue='\E[1;34m';
	brightmagenta='\E[1;35m';
	brightcyan='\E[1;36m';
	brightwhite='\E[1;37m';
	blinkred='\E[5;1;31m';
	blinkgreen='\E[5;1;32m';
	blinkorange='\E[5;1;33m';
	blinkblue='\E[5;1;34';
	blinkmagenta='\E[5;1;35m';
	blinkcyan='\E[5;1;36m';
	blinkwhite='\E[5;1;37m';
	alias ls='ls --color'
}

function lsversion(){
	# display version information 
	echo "LazyScripts ver$LZS_VERSION"
}

function lscolorprompt() {
	# sets a fancy colorized bash shell prompt
	local GRAY="\[\033[1;30m\]"
	local LIGHT_GRAY="\[\033[0;37m\]"
	local CYAN="\[\033[0;36m\]"
	local LIGHT_CYAN="\[\033[1;36m\]"
	local NORM="\[\033[0m\]"
	local LIGHT_BLUE="\[\033[1;34m\]" 
	local YELLOW="\[\033[1;33m\]" 
	local BLUE="\[\033[0;34m\]" 
	local RED="\[\e[1;31m\]"
	local GREEN="\[\e[1;32m\]"
	local BROWN="\[\e[0;33m\]"

        if [ "${distro}" == "Redhat/CentOS" ]; then
                export PS1="$BLUE[$RED\000LZShell$LIGHT_BLUE \t$BLUE]$GRAY=$LIGHT_GRAY-$GRAY=$BLUE<$RED${distro}$BLUE>$GRAY=$LIGHT_GRAY-$GRAY=$BLUE($CYAN\u$GRAY @ $LIGHT_CYAN\H$BLUE)\n$BLUE($YELLOW\w$BLUE)$NORM # "
        elif [ "${distro}" == "Ubuntu" ]; then
                export PS1="$BLUE[$RED\000LZShell$LIGHT_BLUE \t$BLUE]$GRAY=$LIGHT_GRAY-$GRAY=$BLUE<$BROWN${distro}$BLUE>$GRAY=$LIGHT_GRAY-$GRAY=$BLUE($CYAN\u$GRAY @ $LIGHT_CYAN\H$BLUE)\n$BLUE($YELLOW\w$BLUE)$NORM # "
        else
                bwprompt
        fi  
}

function lsbwprompt() {
	# A more simple b&w compatible shell prompt
	PS1="[\h \t]-(\w)# "
}

# ostype - Determine Linux distribution
function ostype() {
	if [ -e /etc/redhat-release ]; then
		export distro="Redhat/CentOS"
	elif [ "$(lsb_release -d | awk '{print $2}')" == "Ubuntu" ]; then
		export distro="Ubuntu"
	else
		echo -e "Could not detect distribution type." && export distro="Other"
	fi
}

function lsinfo() {
        echo -e "----- Operating System -----"
        if [ "${distro}" == "Redhat/CentOS" ]; then
                cat /etc/redhat-release
        elif [ "${distro}" == "Ubuntu" ]; then
                lsb_release -d
        else
                echo "Could not detect distribution type."
        fi
	echo -e "----- Disk Utilization -----"
	df -l -h /
	echo -e "----- Memory Information -----"
	free -m
	echo -e "----- Network Interfaces -----"
	lsip
	echo -e "----- Uptime / Who is Online -----"
	uptime ; who
}

function lscpchk() {
	# Check for Plesk
	if [ -f /usr/local/psa/version ]; then
		hmpsaversion=$( cat /usr/local/psa/version )
		echo -e "$brightyellow\bPlesk Detected: $brightblue\b $hmpsaversion. $norm\n"
	# Check for cPanel
	elif [ -d /usr/local/cpanel ]; then
		hmcpanversion=$( /usr/local/cpanel/cpanel -V )
		echo -e "$brightyellow\bcPanel Detected: $brightblue\b $hmcpanversion. $norm\n"
	else
		echo -e "$brightred\bNo Control Panel Detected.$norm"
	fi
}

function lsresize() {
	if [ "${distro}" == "Redhat/CentOS" ]; then
		if [ -z "`which resize`" ]; then
			echo "Installing xterm"
			yum -y install xterm
			resize
		else
			echo "resizing xterm"
			resize
		fi
	fi
	if [ "${distro}" == "Ubuntu" ]; then
		if [ -z "`which resize`" ]; then
			echo "Installing xterm"
			apt-get -y install xterm
			resize
		else
			echo "resizing xterm"
			resize
		fi
	fi
}

function lsbigfiles() {
	echo -e "[ls-scr] $brightyellow\b List the top 50 files based on disk usage. $norm"
	find / -type f -printf "%s %h/%f\n" | sort -rn -k1 | head -n 50 | awk '{ print $1/1048576 "MB" " " $2}'
}

function lsmytuner() {
	lsinstall bc
	lz tuning-primer
}

# lsinstall - Distro-agnostic quick installer 
function lsinstall() {
	if [[ -z $(which "$1" 2>-) ]]; then
		if [[ ${distro} == "Redhat/CentOS" ]]; then
			rpm -qa | egrep "^$1" &>- || yum -y install $1 &>-
		elif [[ ${distro} == "Ubuntu" ]]; then
			dpkg -l | egrep "^$1" &>- || apt-get -y install $1 &>-
		else
			echo "[ERROR] Unknown distribution. Exiting"
			exit 1
		fi
	fi
}	

function lscloudkick() {
	echo -e "\e[1;34mFunction deprecated\e[0m"
}	

function lsmylogin() {
# MySQL login helper
mysql_client=$( which mysql )
if [ -x $mysql_client ]; then
if [ -e /etc/psa/.psa.shadow ]; then
echo -e "[ls-scr] $brightyellow \bUsing Plesk's admin login. $norm"
mysql -u admin -p`cat /etc/psa/.psa.shadow`
else
i
if [ -e /root/.my.cnf ]; then
echo -e "[ls-scr] $brightwhite \bFound a local $brightyellow \bmy.cnf $brightwhite \bin root's homedir, attempting to login without password prompt. $norm"
$mysql_client
if [ "$?" -ne "0" ]; then
echo -e "[ls-scr] $brightred \bFailed! $norm \bprompting for MySQL root password.$norm"
fi
else
echo -e "[ls-scr] $brightmagenta \bCould not auto-detect MySQL root password - prompting.$norm"
$mysql_client -u root -p
if [ "$?" -ne "0" ]; then
echo -e "[ls-scr] $brightyellow \bMySQL authentication failed or program exited with error.$norm"
fi
fi
fi
else
echo -e "[ls-scr] $brightred\bCould not locate MySQL client in path.$norm"
fi
return 0;
}

function lsapcheck() {
	perl ${LZS_MOD_PATH}apachebuddy.pl ${@}
}

function lsapdocs() {
	if [[ "${distro}" == "Redhat/CentOS" ]]; then
		httpd -S 2>&1|grep -v "^Warning:"|egrep "\/.*\/"|sed 's/.*(\(.*\):.*).*/\1/'|sort|uniq|xargs cat|grep -i DocumentRoot|egrep -v "^#"|awk '{print $2}'|sort|uniq
	elif [[ "${distro}" == "Ubuntu" ]]; then
		apache2ctl -S 2>&1|grep -v "^Warning:"|egrep "\/.*\/"|sed 's/.*(\(.*\):.*).*/\1/'|sort|uniq|xargs cat|grep -i DocumentRoot|egrep -v "^#"|awk '{print $2}'|sort|uniq
	else
		echo "Unsupported OS. You're on your own."
	fi
}

function lshighio() {
	echo "Collecting stats on I/O bound processes for ~10 seconds..."
	n=0
	iofile=$(mktemp)
	m=$((10*10))
	while [[ $n -lt $m ]]; do
		ps ax | awk '$3 ~ /D/ { print $5 }'
		sleep 0.1
		n=$((n+=1))
	done > $iofile
	echo "Top I/O bound processes in the last ~10 seconds."
	sort $iofile | uniq -c | sort -nr | head -n30
}

function lsmyengines() {
	# MySQL login helper
	 mysql_client=$( which mysql )
	 if [ -x $mysql_client ]; then
	   if [ -e /etc/psa/.psa.shadow ]; then
	    echo -e "[ls-scr] $brightyellow \bUsing Plesk's admin login. $norm"
	    $mysql_client -u admin -p`cat /etc/psa/.psa.shadow` -e 'select table_schema, table_name, engine from information_schema.tables;'
	   else
	    i
	if [ -e /root/.my.cnf ]; then
	     echo -e "[ls-scr] $brightwhite \bFound a local $brightyellow \bmy.cnf $brightwhite \bin root's homedir, attempting to login without password prompt. $norm"
	      $mysql_client -e 'select table_schema, table_name, engine from information_schema.tables;'
	      if [ "$?" -ne "0" ]; then
	        echo -e "[ls-scr] $brightred \bFailed! $norm \bprompting for MySQL root password.$norm"
	      fi
	    else
	        echo -e "[ls-scr] $brightmagenta \bCould not auto-detect MySQL root password - prompting.$norm"
	       $mysql_client -u root -p -e 'select table_schema, table_name, engine from information_schema.tables;'
	      if [ "$?" -ne "0" ]; then
	        echo -e "[ls-scr] $brightyellow \bMySQL authentication failed.$norm"
	      fi
	    fi
	   fi
	 else
	   echo -e "[ls-scr] $brightred\bCould not locate MySQL client in path.$norm"
	 fi
	 return 0;
}

function lsapproc() {
	if [ "${distro}" == "Redhat/CentOS" ]; then
		for pid in $(pgrep httpd); do
			echo $pid $(ps -p$pid -ouser|sed '1d') $(pmap -d $pid 2>/dev/null | awk '/private/{print $4}')|tr -d 'K'|awk '{printf "%s %s %s MB\n", $1, $2, $3/1024}'
		done
	elif [[ "${distro}" == "Ubuntu" ]]; then
		for pid in $(pgrep apache2); do
			echo $pid $(ps -p$pid -ouser|sed '1d') $(pmap -d $pid 2>/dev/null | awk '/private/{print $4}')|tr -d 'K'|awk '{printf "%s %s %s MB\n", $1, $2, $3/1024}'
		done
	fi
}

function lsmyusers() {
	#mysql -B -N -e "SELECT DISTINCT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') AS query FROM user" mysql | mysql 
	mysql -e "SELECT User,Host from mysql.user;" && mysql -B -N -e "SELECT user, host FROM user" mysql | sed 's,\t,"@",g;s,^,show grants for ",g;s,$,";,g;' | mysql | sed 's,$,;,g'
}

function lsrblcheck() {
	curl checkrbl.com
}

function lscrtchk() {
	cd $LZS_PREFIX
	read -p "Enter path to key [/path/to/server.key]: " key
	read -p "Enter path to certificate [/path/to/server.crt]: " cert
	CERT_CHECK=$( openssl rsa -in ${key} -modulus -noout | openssl md5 )
	KEY_CHECK=$( openssl x509 -in ${cert} -modulus -noout | openssl md5 )
	if [[ $CERT_CHECK == $KEY_CHECK ]]; then
		echo "Match!"
	else
		echo "No Match! *sad trombone*"
	fi
	cd - > /dev/null 2>&1
}

function lsconcurchk() {
	echo -e "[ls-scr] $brightyellow\b Concurrent connections listed by netstat in numerical order.$norm"

	if [ -n "$1" ]; then
		netstat -an |grep -i tcp |grep -v "0.0.0.0" |grep -v "::" |awk '{print $4, $5}' |awk -F: '{print $2}' |awk '{print $2, $1}' |sort |uniq -c |sort -n |grep $1
	else
	netstat -an |grep -i tcp |grep -v "0.0.0.0" |grep -v "::" |awk '{print $4, $5}' |awk -F: '{print $2}' |awk '{print $2, $1}' |sort |uniq -c |sort -n
	fi
}

# Prints IPv4 addresses for all eth* interfaces
function lsip() {
	/sbin/ifconfig | awk '/^eth/ { printf("%s\t",$1) } /inet addr:/ { gsub(/.*:/,"",$2); if ($2 !~ /^127/) print $2; }'
}

# creates a new MySQL database, and sets a grant statement
function lsmycreate() {
	# Explaining the variables
	#$1=HOST
	#$2=DBNAME
	#$3=DBUSER
	#$4=DBPASS
	
	if [ $# -ne 4 ]; then
		echo "Usage: lsmycreate (host) (database name) (MySQL username) (MySQL password)"
		return 1
	fi
	
	CREATE_DB="CREATE DATABASE IF NOT EXISTS ${2};"
	CREATE_DB_USER="GRANT ALL PRIVILEGES ON ${2}.* TO '${3}'@'${1}' IDENTIFIED BY '${4}';"
	SQL="${CREATE_DB}${CREATE_DB_USER}"
	mysql -e "$SQL"
	echo "${2} created successfully."
}

#Copies an existing database to a new database
function lsmycopy() {
	if [ $# -ne 2 ]; then
		echo "Usage: lsmycopy OLDDBNAME NEWDBNAME"
		return 1
	fi
	mysql -e "CREATE DATABASE IF NOT EXISTS ${2};" && mysqldump -QR ${1} | mysql ${2}
}

function lsap() {
	# This function performs a virtual host list regardless of OS
	if [[ $distro = "Redhat/CentOS" ]]; then
		httpd -S
	elif [ "${distro}" == "Ubuntu" ]; then
		apache2ctl -S
	else
		echo "Unsupported OS"
		return 1
	fi
}

function lshelp() {
    horizontal_row
	echo -e "    lshelp\t\tThis help message."
	echo -e "    lsversion\t\tDisplay the current LazyScripts version."
	echo -e "    lsinfo\t\tDisplay useful system information"
	echo -e "    lsbwprompt\t\tSwitch to a plain prompt."
	echo -e "    lscolorprompt\tSwitch to a fancy colorized prompt."
	echo -e "    lsbigfiles\t\tList the top 50 files based on disk usage."
	echo -e "    lsmytuner\t\tMySQL Tuning Primer"
	echo -e "    lshighio\t\tReports stats on processes in an uninterruptable sleep state."
	echo -e "    lsmylogin\t\tAuto login to MySQL"
	echo -e "    lsmyengines\t\tList MySQL tables and their storage engine."
	echo -e "    lsmyusers\t\tList MySQL users and grants."
	echo -e "    lsmycreate\t\tCreates MySQL DB and MySQL user"
	echo -e "    lsmycopy\t\tCopies an existing database to a new database."
	echo -e "    lsparsar\t\tPretty sar output"
	echo -e "    lsap\t\tShow a virtual host listing."
	echo -e "    lsapcheck\t\tVerify apache max client settings and memory usage."
	echo -e "    lsapdocs\t\tPrints out Apache's DocumentRoots"
	echo -e "    lsapproc\t\tShows the memory used by each Apache process"
	echo -e "    lsrblcheck\t\tServer Email Blacklist Check"
	echo -e "    lscloudkick\t\t**deprecated** Install the Cloudkick agent"
	echo -e "    lsvsftpd\t\tInstalls and configures VSFTPD"
	echo -e "    lsvhost\t\tAdd an Apache virtual host"
	echo -e "    lshppool\t\tCreate a new HAProxy pool"
	echo -e "    lspostfix\t\tSet up Postfix for relaying email"
	echo -e "    lslsync\t\tInstall lsyncd (2.1.5) and configure this server as a master"
	echo -e "    lswordpress\t\tInstall Wordpress on this server"
	echo -e "    lsdrupal\t\tInstall Drupal 7 on this server"
	echo -e "    lswebmin\t\tInstall Webmin on this server"
	echo -e "    lsvarnish\t\tInstall Varnish on this server"
	echo -e "    lsconcurchk\t\tShow concurrent connections"
	echo -e "    lscrtchk\t\tCheck SSL Cert/Key to make sure they match"
	echo -e "    lsrpaf\t\tInstall mod_rpaf to set correct client IP behind a proxy."
	echo -e "    lsnginx\t\tInstalls Nginx and PHP-FPM; Does not work on Ubuntu 10.04"
	echo -e "    lspma\t\tInstalls phpMyAdmin."
	echo -e "    lsnodejs\t\tInstall Node.js with NPM"
	echo -e "    lshaproxy\t\tInstall HAProxy on this server"
	echo -e "    lsapitools\t\tInstall Rackspace API tools"
	echo -e "    lswhatis\t\tOutput the script that would be run with a specific command."
	echo -e "    lsrecap\t\tInstalls the Recap tool https://github.com/rackerlabs/recap."
	echo -e "    lsnova\t\tPrompts for Rackspace API Information."
    horizontal_row
}

function horizontal_row() {
        local COLUMNS=$(tput cols)
        local CHAR=${1:--}
        let "COLUMNS = $COLUMNS / ${#CHAR}"
        for i in $(seq $COLUMNS); do
                echo -n "$CHAR"
        done
        echo
}

function lswhatis() { export -f $1; export -pf; export -fn $1; }

function _aliases() {
	alias lsvhost="lz vhost"
	alias lsdrupal="lz drupal"
	alias lsrpaf="lz rpaf"
	alias lsparsar="lz parsar"
	alias lspostfix="lz postfix"
	alias lspma="lz pma"
	alias lslsync="lz lsync"
	alias lsvarnish="lz varnish"
	alias lsvsftpd="lz vsftpd"
	alias lswebmin="lz webmin"
	alias lswordpress="lz wordpress"
	alias lsnodejs="lz nodejs"
	alias lshaproxy="lz haproxy"
	alias lshppool="lz hppool"
	alias lsnginx="lz nginx"
	alias lsapitools="lz apitools"
	alias lsrecap="lz recap"
}

function lslogin() {
	# Set of commands to run at login
	lsresize
	tset -s xterm
	clear
	lscolors
	lsinfo
	lscolorprompt
	lscpchk
	# Print the MOTD
	cat /etc/motd
	echo -e "LazyScripts Project Page - https://github.com/hhoover/lazyscripts"
}

function lsnova() {
	if [[ -a ~/.novarc ]]; then
	echo -e "NovaRC file found sourcing file."
	source ~/.novarc
	else
	read -p "Rackspace Username: " rsusername
	#read -p "Rackspace Account Number: " rsddi
	read -p "Rackspace API Key: " rsapikey
	read -p "Region (LON/DFW/ORD): " region
cat >~/.novarc <<EOL
	OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
	OS_VERSION=2.0
	OS_AUTH_SYSTEM=rackspace
	OS_REGION_NAME=$region
	OS_SERVICE_NAME=cloudserversOpenStack
	OS_TENANT_NAME=$rsusername
	OS_USERNAME=$rsusername
	OS_PASSWORD=$rsapikey
	OS_NO_CACHE=1
	export OS_AUTH_URL OS_VERSION OS_AUTH_SYSTEM OS_REGION_NAME OS_SERVICE_NAME OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_NO_CACHE
EOL
	source ~/.novarc
	fi
}

# Run these functions at source time
ostype
complete -F _lz lz	# Tab completion stuff
_aliases	 # Export the function aliases
