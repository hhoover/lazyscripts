#!/bin/bash
# Adds a pool to an existing HAProxy config

function function_info() {
clear
echo "This configures a new pool for HAProxy"
echo "ONLY USE FOR BOTH HTTP AND HTTPS. **If you only need HTTP, CTRL-C NOW!**"
}

function list_ips() {
	echo "Available IP addresses:"
	/sbin/ifconfig | awk '/^eth/ { printf("%s\t",$1) } /inet addr:/ { gsub(/.*:/,"",$2); if ($2 !~ /^127/) print $2; }'
}

function get_info() {
	# Get installation variables from the user
# READ IN INSECURE HOSTS
	read -p "What IP should be used for the new web pool? (Don't use an IP already in use by HAProxy)" BAL_IP
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
}

function config_haproxy() {
# Backup the config
	cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.$( date +%Y%m%d )

# Set global and INSCURE defaults
	cat >> /etc/haproxy/haproxy.cfg <<-EOF

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
list_ips
get_info
config_haproxy
service haproxy restart
echo "Complete!"