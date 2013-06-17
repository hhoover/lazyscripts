#!/bin/bash
# Postfix configurator
# based on Kale's super happy kitty Postfix configurator

# pause 
function pause() {
    key=""
    echo -n Hit any key to continue....
    stty -icanon
    key=`dd count=1 2>/dev/null`
    stty icanon
}

# are we root?
function root_check() {
	if [[ $EUID -ne 0 ]]; then
	   echo "This script must be run as root." 1>&2
	   exit 1
	fi
}

# let's get some info
function get_info() {
	echo "Today we'll be configurating this server for outgoing mail relay. ANSWER THE"
	echo "QUESTIONS TRUTHFULLY AS THERE WILL BE A QUIZ LATER!!!!!"
	echo 
	read -p "Relay SMTP server: " RELAYHOST

	read -p "SMTP Username: " USERNAME

	read -p "SMTP Password: " PASSWERD
}

# WERE DOIN IT LIVE
function install_postfix() {
echo "About to configure outgoing mail. Any existing postfix config will be backed up" 
echo "to /etc/postfix/main.cf.orig. Hit ctrl-C to cancel, or enter to goooooooooo..."

pause

	if [[ $distro == "Redhat/CentOS" ]]; then
		yum -q -y install postfix cyrus-sasl-plain cyrus-sasl-md5  > /dev/null 2>&1
		chkconfig postfix on
	elif [[ $distro == "Ubuntu" ]]; then
		export DEBIAN_FRONTEND=noninteractive
		apt-get -q -y install postfix libsasl2-modules  > /dev/null 2>&1
		export DEBIAN_FRONTEND=dialog
	fi
	cp -a /etc/postfix/main.cf /etc/postfix/main.cf.orig
}

function configure_postfix() {

# Set up the relay
	if [[ $RELAYHOST == "secure.emailsrvr.com" ]]; then
		cat >> /etc/postfix/main.cf <<-EOF
		relayhost = secure.emailsrvr.com
		smtp_sasl_auth_enable=yes
		smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
		smtp_sasl_mechanism_filter = AUTH LOGIN
		smtp_sasl_security_options =
		smtp_generic_maps = hash:/etc/postfix/generic
		EOF
	elif [[ $RELAYHOST == "smtp.gmail.com" ]]; then
		cat >> /etc/postfix/main.cf <<-EOF
		relayhost = [smtp.gmail.com]:587
		smtp_use_tls = yes
		smtp_sasl_auth_enable=yes
		smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
		smtp_sasl_mechanism_filter = AUTH LOGIN
		smtp_sasl_security_options =
		smtp_generic_maps = hash:/etc/postfix/generic
			EOF
	elif [[ $RELAYHOST == "smtp.sendgrid.net" ]]; then
		cat >> /etc/postfix/main.cf <<-EOF
		relayhost = [smtp.sendgrid.net]:587
		smtp_sasl_auth_enable = yes
		smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
		smtp_sasl_security_options = noanonymous
		smtp_tls_security_level = may
		header_size_limit = 4096000
		smtp_generic_maps = hash:/etc/postfix/generic
		EOF
	else
		cat >> /etc/postfix/main.cf <<-EOF
		relayhost = $RELAYHOST
		smtp_sasl_auth_enable=yes
		smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
		smtp_sasl_mechanism_filter = AUTH LOGIN
		smtp_sasl_security_options =
		smtp_generic_maps = hash:/etc/postfix/generic
		EOF
	fi
# configure authentication
echo "$RELAYHOST $USERNAME:$PASSWERD" > /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
if [[ $distro == "Redhat/CentOS" ]]; then
	echo "apache ${USERNAME}" > /etc/postfix/generic
elif [[ $distro == "Ubuntu" ]]; then
	echo "www-data ${USERNAME}" > /etc/postfix/generic	
else
	echo "OMG BROKEN"
	exit 1
fi
}

root_check
get_info
install_postfix
configure_postfix
echo -ne "\007"
echo "Ding fries are done! Now, try to send a mail and check the logs; ensure that"
echo "the mail sent successfully (status=sent) and that it was properly relayed"
echo "(relay=${RELAYHOST})."
sleep 1
postmap /etc/postfix/generic > /dev/null 2>&1
service postfix restart > /dev/null 2>&1
exit 0
