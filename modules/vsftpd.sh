#!/bin/bash
# Author: Hart Hoover
# Installs vsftpd on CentOS, RHEL, and Ubuntu

function install_vsftpd() {
	if [[ ${distro} = "Redhat/CentOS" ]]; then
		if [ -f /etc/vsftpd/vsftpd.conf ]; then
			echo "vsftpd might be already installed! Exiting."
			exit 1
		fi
		yum -y -q install vsftpd
		echo "vsftpd installed."
	elif [ ${distro} == "Ubuntu" ]; then
		if [ -f /etc/vsftpd.conf ]; then
			echo "vsftpd might be already installed! Exiting."
			exit 1
		fi
		apt-get -y -q install vsftpd > /dev/null 2>&1
		echo "vsftpd installed."
	else
		echo "Unsupported OS. Exiting."
		exit 1
	fi
}

function check_21() {
        if netstat -ntlp | grep 21 2>/dev/null
        then
        echo -e "\a\n Something is running on port 21"
        echo -e "\a\n Closing Script"
        exit 1
        else
        echo -e "\a\n Nothing Running on port 21"
        fi
}


function configure_vsftpd() {
	if [[ ${distro} = "Redhat/CentOS" ]]; then
		mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.orig
		echo "vsftpd.conf backed up to vsftpd.conf.orig"
		modprobe ip_conntrack_ftp
		cat > /etc/vsftpd/vsftpd.conf <<-EOF
		anonymous_enable=NO
		local_enable=YES
		write_enable=YES
		local_umask=022
		dirmessage_enable=YES
		xferlog_enable=YES
		connect_from_port_20=YES
		xferlog_std_format=YES
		listen=YES
		pam_service_name=vsftpd
		userlist_enable=YES
		tcp_wrappers=YES
		pasv_min_port=60000
		pasv_max_port=65000
		chroot_local_user=YES
		chroot_list_enable=YES
		chroot_list_file=/etc/vsftpd/vsftpd.chroot_list
		EOF
		touch /etc/vsftpd/vsftpd.chroot_list
		service vsftpd restart > /dev/null 2>&1
		chkconfig vsftpd on
		echo "VSFTPD configured."
	elif [ ${distro} == "Ubuntu" ]; then
			mv /etc/vsftpd.conf /etc/vsftpd.conf.orig
			echo "vsftpd.conf backed up to vsftpd.conf.orig"
			cat > /etc/vsftpd.conf <<-EOF
			anonymous_enable=NO
			local_enable=YES
			write_enable=YES
			local_umask=022
			dirmessage_enable=YES
			xferlog_enable=YES
			connect_from_port_20=YES
			xferlog_std_format=YES
			listen=YES
			pam_service_name=vsftpd
			userlist_enable=YES
			tcp_wrappers=YES
			pasv_min_port=60000
			pasv_max_port=65000
			chroot_local_user=YES
			chroot_list_enable=YES
			chroot_list_file=/etc/vsftpd.chroot_list
			EOF
			touch /etc/vsftpd.chroot_list
			touch /etc/vsftpd.user_list
			service vsftpd restart > /dev/null 2>&1
			echo "VSFTPD configured."
	else
		echo "Unsupported OS. Exiting."
		exit 1
	fi
}

function configure_firewall() {
	if [[ ${distro} = "Redhat/CentOS" ]]; then
		iptables -I INPUT -p tcp --dport 21 -m comment --comment "FTP" -j ACCEPT
		iptables -I INPUT -p tcp -m multiport --dports 60000:65000 -m comment --comment "FTP passive mode ports" -j ACCEPT
		/etc/init.d/iptables save
		echo "Firewall open on ports 21 and 60000:65000"
	elif [ ${distro} == "Ubuntu" ]; then
		ufw allow 21
		ufw allow proto tcp from any to any port 60000:65000
		echo "Firewall open on ports 21 and 60000:65000"
	else
		echo "Unsupported OS. Exiting."
		exit 1
	fi
}

echo "Checking Port 21"
check_21
echo "Beginning vsftpd installation"
install_vsftpd
echo "Configuring vsftpd"
configure_vsftpd
configure_firewall
echo "vsftpd installation complete."
exit 0
