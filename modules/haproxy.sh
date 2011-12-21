#!/bin/bash
# Installs and configures HAProxy for balancing servers

function function_info() {
clear
echo "This installs HAProxy as a load balancer."
echo "Coming soon: lsheartbeat"
echo "For now, you need to set up heartbeat manually if you need failover."
echo "ONLY USE FOR BOTH HTTP AND HTTPS. **If you only need HTTP, CTRL-C NOW!**"
}

function check_existing() {
	# checks for an existing install
	if [[ $distro = "Redhat/CentOS" ]]; then
		rpm -q haproxy > /dev/null 2>&1
	if [[ $? = 0 ]]; then
		echo "HAProxy might be already installed! Check yourself before you wreck yourself."
		exit 1
	fi
elif [[ $distro = "Ubuntu" ]]; then
	if [[ -n $( dpkg -s haproxy | grep installed ) ]]; then
		echo "HAProxy might be already installed! Check yourself before you wreck yourself."
		exit 1
	fi
fi
}

function list_ips() {
	echo "Available IP addresses:"
	/sbin/ifconfig | awk '/^eth/ { printf("%s\t",$1) } /inet addr:/ { gsub(/.*:/,"",$2); if ($2 !~ /^127/) print $2; }'
}

function get_info() {
	# Get installation variables from the user
# READ IN INSECURE HOSTS
	read -p "What IP should be used for the web pool? " BAL_IP
	read -p "Please enter a name for the pool (domain.com): " POOL_NAME
	read -p "How many INSECURE servers will be load balanced? (port 80): " -e N_HOSTS
	N_HOSTS=${N_HOSTS:-1}
	for ((i=1; i <= $N_HOSTS; i++)); do
		read -p "Server IP #${i}: " -e BAL_HOSTS80[$i]
	done
	unset N_HOSTS
	
# READ IN SECURE HOSTS
	read -p "How many SECURE servers will be load balanced? (port 443): " -e N_HOSTS
	N_HOSTS=${N_HOSTS:-1}
	for ((i=1; i <= $N_HOSTS; i++)); do
		read -p "Server IP #${i}: " -e BAL_HOSTS443[$i]
	done
	unset N_HOSTS

#Set admin password
ADMIN_PASSWORD=$( apg -m 7 -n 1 )
}

function install_haproxy() {
	if [[ $distro = "Redhat/CentOS" ]]; then
		yum -q -y install haproxy > /dev/null 2>&1
		chkconfig haproxy on
	elif [[ $distro = "Ubuntu" ]]; then
		apt-get -q -y install haproxy > /dev/null 2>&1
	else
		echo "Unsupported OS"
		return 1
	fi
}

function config_haproxy() {
# Backup the config
	mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig

# Set global and INSCURE defaults
	cat > /etc/haproxy/haproxy.cfg <<-EOF
	global
	        maxconn 40960
	        user haproxy
	        group haproxy
	        daemon

	defaults
	        log     global
	        mode    http
	        option  dontlognull
	        retries 3
	        option redispatch
	        timeout client 10s
	        timeout server 40s
	        timeout connect 4s
	        maxconn 40960
		
listen admin ${BAL_IP}:81
	mode http
	stats enable
	stats uri /haproxy
	stats auth admin:${ADMIN_PASSWORD}

listen ${POOL_NAME} ${BAL_IP}:80
	mode http
	cookie webpool insert
	balance leastconn
	option forwardfor
	option httpclose
	EOF

# Add INSECURE hosts (port 80)	
for HOST80 in ${BAL_HOSTS80[*]}; do
	cat >> /etc/haproxy/haproxy.cfg <<-EOF
	server ${HOST80} ${HOST80}:80 cookie webpool_${HOST80} check
	EOF
done
	
# Add SSL defaults
cat >> /etc/haproxy/haproxy.cfg <<-EOF

listen ${POOL_NAME}-ssl ${BAL_IP}:443
	mode tcp
	balance source
EOF

# Add SECURE hosts (port 443)	
for HOST443 in ${BAL_HOSTS443[*]}; do
	cat >> /etc/haproxy/haproxy.cfg <<-EOF
server ${HOST443} ${HOST443}:443 check
EOF
done
}

function_info
check_existing
list_ips
get_info
install_haproxy
config_haproxy
service haproxy start
echo "Complete!"
echo "HAProxy Login credentials: admin:${ADMIN_PASSWORD}"