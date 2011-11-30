#!/bin/bash
# LazyScripts Initializer Script
# https://github.com/hhoover/lazyscripts/
#
# Usage: dot (`. ls-init.sh`) or source this file (`source ls-init.sh`)
#        to load into your current shell
#

LZS_VERSION=003
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
	elif [ -r "${FILE}" ]; then
		# Execute the module
		chmod +x ${FILE} && ${FILE} "$*"
	else
		return 1
	fi
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
		hmcpanversion=$( cat /usr/local/cpanel/version )
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
	if [[ $distro = "Redhat/CentOS" ]]; then
		cat > /etc/yum.repos.d/cloudkick.repo <<-EOF
		[cloudkick]
		name=Cloudkick
		baseurl=http://packages.cloudkick.com/redhat/x86_64
		gpgcheck=0
		EOF
		yum -y -q install cloudkick-agent
		chkconfig cloudkick-agent on
		echo -e "Please enter the login credentials and $blinkred\bstart the agent. $norm"
		cloudkick-config
	elif [ "${distro}" == "Ubuntu" ]; then
		echo 'deb http://packages.cloudkick.com/ubuntu lucid main' > /etc/apt/sources.list.d/cloudkick.list
		curl http://packages.cloudkick.com/cloudkick.packages.key | apt-key add -
		apt-get -q update
		apt-get -y -q install cloudkick-agent
		echo -e "Please enter the login credentials and $blinkred\bstart the agent. $norm"
		cloudkick-config
	else 
		echo "Unsupported OS. See https://support.cloudkick.com/Category:Installing_Cloudkick"
		exit
	fi
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

function lshelp() {
	echo -e "---------------------------------------------------------------------------------------------"
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
	echo -e "    lsapcheck\t\tVerify apache max client settings and memory usage."
	echo -e "    lsapdocs\t\tPrints out Apache's DocumentRoots"
	echo -e "    lsapproc\t\tShows the memory used by each Apache process"
	echo -e "    lsrblcheck\t\tServer Email Blacklist Check"
	echo -e "    lscloudkick\t\tInstall the Cloudkick agent"
	echo -e "    lsvsftpd\t\tInstalls and configures VSFTPD"
	echo -e "    lsvhost\t\tAdd an Apache virtual host"
	echo -e "    lspostfix\t\tSet up Postfix for relaying email"
	echo -e "    lslsync\t\tInstall lsyncd and configure this server as a master"
	echo -e "    lswordpress\t\tInstall Wordpress on this server"
	echo -e "    lsdrupal\t\tInstall Drupal 7 on this server"
	echo -e "    lswebmin\t\tInstall Webmin on this server"
	echo -e "    lsvarnish\t\tInstall Varnish on this server"
	echo -e "    lssuphp\t\tReplaces mod_php with mod_suphp"
	echo -e "    lsconcurchk\t\tShow concurrent connections"
	echo -e "    lscrtchk\t\tCheck SSL Cert/Key to make sure they match"
	echo -e "    lsrpaf\t\tInstall mod_rpaf to set correct client IP behind a proxy."
	echo -e "    lspma\t\tInstalls phpMyAdmin."
	echo -e "    lsnodejs\t\tInstall Node.js with NPM"
	echo -e "    lswhatis\t\tOutput the script that would be run with a specific command."
	echo -e "---------------------------------------------------------------------------------------------"
}

function lswhatis() { export -f $1; export -pf; export -fn $1; }

function _aliases() {
	alias lsvhost="lz vhost"
	alias lsapcheck="lz apachebuddy"
	alias lsdrupal="lz drupal"
	#alias lshistsetup="lz hist"
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
}

function lslogin() {
	# Set of commands to run at login
	lsresize
	tset -s xterm
	clear
	lscolors
	lsinfo
	lscolorprompt
	#lz hist
	lscpchk
	# Print the MOTD
	cat /etc/motd
	echo -e "LazyScripts Project Page - https://github.com/hhoover/lazyscripts"
}

# Run these functions at source time
ostype
_aliases	 # Export the function aliases

# Temporary RedHat/CentOS Fix
if [[ $distro == "Redhat/CentOS" ]]; then
	chmod 644 /etc/resolv.conf
fi

