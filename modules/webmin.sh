#!/bin/bash
# webmin.sh
# Installs Webmin for fun and profit

# Set up a repo and install
function install_webmin() {
	if [[ $distro == "Redhat/CentOS" ]]; then
		cat > /etc/yum.repos.d/webmin.repo <<-EOF
		[Webmin]
		name=Webmin Distribution Neutral
		#baseurl=http://download.webmin.com/download/yum
		mirrorlist=http://download.webmin.com/download/yum/mirrorlist
		enabled=1
		EOF
		curl -s http://www.webmin.com/jcameron-key.asc -o "/tmp/jcameron-key.asc"
                rpm --import /tmp/jcameron-key.asc > /dev/null 2>&1
                rm -f /tmp/jcameron-key.asc
		yum -y -q install webmin perl-Net-SSLeay
		iptables -I INPUT -m tcp -p tcp --dport 10000 -j ACCEPT
		service iptables save > /dev/null 2>&1
	elif [[ $distro == "Ubuntu" ]]; then
		echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
		echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list
		wget -q http://www.webmin.com/jcameron-key.asc
		apt-key add jcameron-key.asc > /dev/null 2>&1
		rm -f jcameron-key.asc
		apt-get -q update > /dev/null 2>&1
		apt-get -q -y install webmin > /dev/null 2>&1
		ufw allow 10000 > /dev/null 2>&1
	else
		echo "Unsupported OS"
		exit 1
	fi
}

echo "Beginning Installation"
install_webmin
echo "Webmin installation complete. Port 10000 is open."
