#!/bin/bash
#

LZS_VERSION=001
LZS_PREFIX="/root/.lazyscripts/tools"
LZS_APP="$LZS_PREFIX/ls-init.sh"
LZS_URLPREFIX="git://github.com/hhoover/lazyscripts.git"
LZS_GETURL="$LZS_URLPREFIX/ls-init.sh"
MYTUNERAPP="mysqltuner.pl"


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
    PS1="$BLUE[$CYAN\000LZShell$LIGHT_BLUE \t$BLUE]$GRAY=$LIGHT_GRAY-$GRAY=$BLUE<$CYAN`uname -sm`$BLUE>$GRAY=$LIGHT_GRAY-$GRAY=$BLUE($CYAN\u$GRAY @ $LIGHT_CYAN\H$BLUE)\n$BLUE($YELLOW\w$BLUE)$NORM # "
}

function lsbwprompt() {
# A more simple b&w compatible shell prompt
    PS1="[\h \t]-(\w)# "
}

function ostype() {

    if [ -e /etc/redhat-release ]; then
        distro="redhat"
    else
        if [ "$(lsb_release -d | awk '{print $2}')" == "Ubuntu" ];then
        distro="debian"
    else
        echo -e "could not detect operating system" && distro="other"
    
    fi
fi
}

function lsinfo() {
echo -e "----- Operating System -----"
    if [ -e /etc/redhat-release ]; then
        cat /etc/redhat-release
    else
        if [ "$(lsb_release -d | awk '{print $2}')" == "Ubuntu" ];then
            lsb_release -d
    else
        echo -e "could not detect operating system" && distro="other"
    
    fi
fi
echo -e "----- Disk Utilization -----"
df -l -h
echo -e "----- Memory Information -----"
free -m
echo -e "----- Uptime / Who is Online -----"
uptime ; who
}

function lscpchk() {
# Check for Plesk
if [ -f /usr/local/psa/version ]; then
        hmpsaversion=`cat /usr/local/psa/version`
        echo -e "$brightyellow\bPlesk Detected: $brightblue\b $hmpsaversion. $norm\n"
# Check for cPanel
elif [ -f /usr/local/cpanel/version ]; then
		hmcpanversion=`cat /usr/local/cpanel/version`
		echo -e "$brightyellow\bcPanel Detected: $brightblue\b $hmcpanversion. $norm\n"
else
        echo -e "$brightred\bNo Control Panel Detected.$norm"
     fi
}

function lsresize() {

if [ "${distro}" == "redhat" ]; then
    if [ -z "`which resize`" ]; then
        echo "Installing xterm"
        yum -y install xterm
        resize
    else
        echo "resizing xterm"
        resize
    fi
fi
    if [ "${distro}" == "debian" ]; then
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

function lsmytuner(){
# Get Major Hayden's mysqltuner.pl script
# https://github.com/rackerhacker/MySQLTuner-perl
if [ -e $MYTUNERAPP ]; then
 rm $MYTUNERAPP
fi
echo -e "[ls-scr] $brightwhite\bRetrieving latest version of MySQL Tuner"
cd $LZS_PREFIX ; wget -q http://mysqltuner.pl
if [ "$?" -eq "0" ]; then
  chmod +x $MYTUNERAPP
  perl $MYTUNERAPP
else
  echo -e "[ls-scr] $brightred\bError retrieving latest version of MySQLTuner. Please file a bug report: https://github.com/hhoover/lazyscripts $norm"
fi
}

function lsmylogin() {
# MySQL login helper
 mysql_client=`which mysql`
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
	if [ "${distro}" == "redhat" ]; then
	    if [ -z "`which perl`" ]; then
	        echo "Installing perl"
	        yum -y install perl
		fi
	fi
	    if [ "${distro}" == "debian" ]; then
	        if [ -z "`which perl`" ]; then
	        echo "Installing perl"
	        apt-get -y install perl
	    fi
	fi
$PERL=`which perl`
$PERL $LZS_PREFIX/apachebuddy.pl
}

function lsapdocs() {
	if [[ "${distro}" == "redhat" ]]
		then
    httpd -S 2>&1|grep -v "^Warning:"|egrep "\/.*\/"|sed 's/.*(\(.*\):.*).*/\1/'|sort|uniq|xargs cat|grep -i DocumentRoot|egrep -v "^#"|awk '{print $2}'|sort|uniq
	elif [[ "${distro}" == "debian" ]]
		then
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
	 mysql_client=`which mysql`
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
if [ "${distro}" == "redhat" ]; then
	for pid in $(pgrep httpd); do
		echo $pid $(ps -p$pid -ouser|sed '1d') $(pmap -d $pid 2>/dev/null | awk '/private/{print $4}')|tr -d 'K'|awk '{printf "%s %s %s MB\n", $1, $2, $3/1024}'
	done
fi
if [[ "${distro}" == "debian" ]]; then
	for pid in $(pgrep apache2); do
		echo $pid $(ps -p$pid -ouser|sed '1d') $(pmap -d $pid 2>/dev/null | awk '/private/{print $4}')|tr -d 'K'|awk '{printf "%s %s %s MB\n", $1, $2, $3/1024}'
	done
fi
}

function lsmyusers() {
    mysql -B -N -e "SELECT DISTINCT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') AS query FROM user" mysql | mysql 
}

function lsrblcheck() {
	curl checkrbl.com
}

function lswordpress() {
	cd $LZS_PREFIX
	chmod +x wordpress.sh
	./wordpress.sh
	cd - > /dev/null 2>&1
}

function lspostfix() {
	cd $LZS_PREFIX
	chmod +x postfix.sh
	./postfix.sh
	cd - > /dev/null 2>&1
}

function lswebmin() {
	cd $LZS_PREFIX
	chmod +x webmin.sh
	./webmin.sh
	cd - > /dev/null 2>&1
}

function lslsync() {
	cd $LZS_PREFIX
	chmod +x lsync.sh
	./lsync.sh
	cd - > /dev/null 2>&1
}

function lsvhost() {
	read -p "Please enter a domain (no www): " 	domain
	if [[ $distro = "redhat" ]]; then
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
		EOF
		mkdir -p /var/www/vhosts/$domain
		service httpd restart > /dev/null 2>&1
	elif [[ $distro = "debian" ]]; then
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
		EOF
		mkdir -p /var/www/vhosts/$domain
		a2ensite $domain > /dev/null 2>&1
		service apache2 restart	 > /dev/null 2>&1
	else
		echo "Unsupported OS"
fi
}

function lsconcurchk() {

echo -e "[ls-scr] $brightyellow\b Concurrent connections listed by netstat in numerical order.$norm"

if [ -n "$1" ]; then
netstat -an |grep -i tcp |grep -v "0.0.0.0" |grep -v "::" |awk '{print $4, $5}' |awk -F: '{print $2}' |awk '{print $2, $1}' |sort |uniq -c |sort -n |grep $1
else
netstat -an |grep -i tcp |grep -v "0.0.0.0" |grep -v "::" |awk '{print $4, $5}' |awk -F: '{print $2}' |awk '{print $2, $1}' |sort |uniq -c |sort -n
fi
}

function lshelp() {

echo -e "[ls-scr] $brightred\b LazyScripts Project Page - https://github.com/hhoover/lazyscripts $norm"
echo -e "[ls-scr] ---------------------------------------------------------------------------------------------"
echo -e "[ls-scr] $brightred\b lshelp $norm - $brightblue\b This help message. $norm"
echo -e "[ls-scr] $brightred\b lsversion $norm - $brightblue\b Display the current LazyScripts version. $norm"
echo -e "[ls-scr] $brightred\b lsinfo $norm - $brightblue\b Display useful system information $norm"
echo -e "[ls-scr] $brightred\b lsbwprompt $norm - $brightblue\b Switch to a plain prompt. $norm"
echo -e "[ls-scr] $brightred\b lscolorprompt $norm - $brightblue\b Switch to a fancy colorized prompt. $norm"
echo -e "[ls-scr] $brightred\b lsbigfiles $norm - $brightblue\b List the top 50 files based on disk usage. $norm"
echo -e "[ls-scr] $brightred\b lsmytuner $norm - $brightblue\b MySQL Tuner. $norm"
echo -e "[ls-scr] $brightred\b lshighio $norm - $brightblue\b Reports stats on processes in an uninterruptable sleep state. $norm"
echo -e "[ls-scr] $brightred\b lsmylogin $norm - $brightblue\b Auto login to MySQL $norm"
echo -e "[ls-scr] $brightred\b lsmyengines $norm - $brightblue\b List MySQL tables and their storage engine. $norm"
echo -e "[ls-scr] $brightred\b lsmyusers $norm - $brightblue\b List MySQL users and grants. $norm"
echo -e "[ls-scr] $brightred\b lsapcheck $norm - $brightblue\b Verify apache max client settings and memory usage. $norm"
echo -e "[ls-scr] $brightred\b lsapdocs $norm - $brightblue\b Prints out Apache's DocumentRoots $norm"
echo -e "[ls-scr] $brightred\b lsapproc $norm - $brightblue\b Shows the memory used by each Apache process $norm"
echo -e "[ls-scr] $brightred\b lsrblcheck $norm - $brightblue\b Server Email Blacklist Check $norm"
echo -e "[ls-scr] $brightred\b lsvhost $norm - $brightblue\b Add an Apache virtual host $norm"
echo -e "[ls-scr] $brightred\b lspostfix $norm - $brightblue\b Set up Postfix for relaying email $norm"
echo -e "[ls-scr] $brightred\b lslsync $norm - $brightblue\b Install lsyncd and configure this server as a master$norm"
echo -e "[ls-scr] $brightred\b lswordpress $norm - $brightblue\b Install Wordpress on this server $norm"
echo -e "[ls-scr] $brightred\b lswebmin $norm - $brightblue\b Install Webmin on this server $norm"
echo -e "[ls-scr] $brightred\b lsconcurchk $norm - $brightblue\b Show concurrent connections $norm"
echo -e "[ls-scr] $brightred\b lswhatis $norm - $brightblue\b Output the script that would be run with a specific command. $norm"
echo -e "[ls-scr] ---------------------------------------------------------------------------------------------"
}

function lswhatis() { export -f $1; export -pf; export -fn $1; }

function lslogin() {
# Set of commands to run at login
ostype
lsresize
tset -s xterm
clear
lscolors
lsinfo
lscolorprompt
lscpchk
# Print the MOTD
cat /etc/motd
echo -e "LazyScripts login success - type $brightyellow\b lsinfo$norm for server info or $brightyellow\b lshelp$norm for a list of commands $norm"
}
