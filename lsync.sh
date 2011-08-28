#!/bin/bash
## Lsyncd Installation Script
## Author: David Wittman <david@wittman.com>

SOURCE="http://lsyncd.googlecode.com/files/lsyncd-2.0.5.tar.gz"
BASENAME=$(basename ${SOURCE})
SOURCEDEST=/usr/local/src/$(echo ${BASENAME} | sed 's/\.tar\.gz//')
DEFAULT_PATH="/var/www"

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

pass() {
    COLUMNS=$(tput cols)
    echo $1 | awk -v width=${COLUMNS} '{ padding=(width-length($0)-8); printf "%"(padding)"s", "[  ";}'
    echo -e "${bold}${green}OK${normal}  ]"
}

die() {
    COLUMNS=$(tput cols)
    echo $1 | awk -v width=${COLUMNS} '{ padding=(width-length($0)-8); printf "%"(padding)"s", "[ ";}'
    echo -e "${bold}${red}FAIL${normal} ]"
    exit 1
}
# Usage: /path/to/command || die "This shit didn't work"

# Get installation variables from the user
read -p "How many slave hosts will be synchronized? [1] " -e N_HOSTS
N_HOSTS=${N_HOSTS:-1}
for ((i=1; i <= $N_HOSTS; i++)); do
    read -p "Hostname #${i}: " -e SYNC_HOSTS[$i]
done

read -p "Enter source directory: [${DEFAULT_PATH}] " -e SYNC_SOURCE
# Set SYNC_SOURCE to default if empty
SYNC_SOURCE=${SYNC_SOURCE:-${DEFAULT_PATH}}
read -p "Enter target directory: [${SYNC_SOURCE}] " -e SYNC_TARGET
# Set SYNC_TARGET to SYNC_SOURCE if empty
SYNC_TARGET=${SYNC_TARGET:-${SYNC_SOURCE}}
unset N_HOSTS

if [ ! -d $SYNC_SOURCE ]; then
	/bin/mkdir -p $SYNC_SOURCE
fi

echo "${bold}${distro}${normal} detected."

# Install lua shit
OUTPUT="Installing dependencies..."
printf "$OUTPUT"
if [ "$distro" = "Ubuntu" ]; then
    /usr/bin/apt-get install -yq lua5.1 liblua5.1-0-dev pkg-config rsync > /dev/null || die $OUTPUT
elif [ "$distro" = "Redhat/CentOS" ]; then
    /usr/bin/yum -qy install lua lua-devel pkgconfig > /dev/null || die $OUTPUT
fi
pass "$OUTPUT"

# Download and untar
OUTPUT="Downloading and extracting lsyncd..."
printf "$OUTPUT"
/usr/bin/wget --quiet ${SOURCE} || die $OUTPUT
/bin/mkdir ${SOURCEDEST} || die $OUTPUT
/bin/tar --strip 1 -xf ${BASENAME} -C ${SOURCEDEST} || die $OUTPUT
/bin/rm ${BASENAME}
pass "$OUTPUT"

# Compile and install
OUTPUT="Compiling and installing lsyncd..."
printf "$OUTPUT"
cd ${SOURCEDEST}
./configure &> /dev/null || die $OUTPUT
/usr/bin/make &> /dev/null && /usr/bin/make install &> /dev/null || die $OUTPUT
pass "$OUTPUT"

# Post-install stuff
OUTPUT="Creating configuration files..."
printf "$OUTPUT"
if [ "$distro" = "Ubuntu" ]; then
# Create init script
    cat > /etc/init.d/lsyncd << EOF
#!/bin/bash
#
# lsyncd: Starts the lsync Daemon
#
# chkconfig: 345 99 90
# description: Lsyncd uses rsync to synchronize local directories with a remote
# machine running rsyncd. Lsyncd watches multiple directories
# trees through inotify. The first step after adding the watches
# is to, rsync all directories with the remote host, and then sync
# single file buy collecting the inotify events.
# processname: lsyncd

# . /etc/rc.d/init.d/functions

    config="/etc/lsyncd.lau"
    lsyncd="/usr/local/bin/lsyncd"
    lockfile="/var/lock/lsyncd"
    prog="lsyncd"
    RETVAL=0

    start() {
        if [ -f \$lockfile ]; then
        echo -n $"\$prog is already running: "
        echo
        else
        echo -n $"Starting \$prog: "
        \$lsyncd \$config
        RETVAL=\$?
        echo
        [ \$RETVAL = 0 ] && touch \$lockfile
        return \$RETVAL
        fi
    }

    stop() {
        echo -n $"Stopping \$prog: "
        killall \$lsyncd
        RETVAL=\$?
        echo
        [ \$RETVAL = 0 ] && rm -f \$lockfile
        return \$RETVAL
    }

    case "\$1" in
        start)
        start
        ;;
        stop)
        stop
        ;;
        restart)
        stop
        start
        ;;
        status)
        status \$lsyncd
        ;;
        *)

        echo "Usage: lsyncd {start|stop|restart|status}"
        exit 1
    esac

    exit \$?
EOF

# Create script to auto-start lsyncd at boot
    cat > /etc/init/lsyncd.conf << EOF
# lsyncd - synchronization program
#
#

description     "lsyncd"

# Make sure we start before an interface receives traffic
start on (starting network-interface
          or starting network-manager
          or starting networking)

stop on runlevel [!023456]

respawn
respawn limit 10 5

pre-start exec /etc/init.d/lsyncd start
post-stop exec /etc/init.d/lsyncd stop
EOF
    /bin/chmod 644 /etc/init/lsyncd.conf

# Post-install stuff for Redhat based OSes
elif [ "$distro" = "Redhat/CentOS" ]; then
# Create init script
    cat > /etc/init.d/lsyncd << EOF
#!/bin/bash
#
# lsyncd: Starts the lsync Daemon
#
# chkconfig: 345 99 90
# description: Lsyncd uses rsync to synchronize local directories with a remote
# machine running rsyncd. Lsyncd watches multiple directories
# trees through inotify. The first step after adding the watches
# is to, rsync all directories with the remote host, and then sync
# single file buy collecting the inotify events.
# processname: lsyncd

. /etc/rc.d/init.d/functions

config="/etc/lsyncd.lau"
lsyncd="/usr/local/bin/lsyncd"
lockfile="/var/lock/subsys/lsyncd"
prog="lsyncd"
RETVAL=0

start() {
    if [ -f \$lockfile ]; then
    echo -n $"\$prog is already running: "
    echo
    else
    echo -n $"Starting \$prog: "
    daemon \$lsyncd \$config
    RETVAL=\$?
    echo
    [ \$RETVAL = 0 ] && touch \$lockfile
    return \$RETVAL
    fi
}

stop() {
    echo -n $"Stopping \$prog: "
    killproc \$lsyncd
    RETVAL=\$?
    echo
    [ \$RETVAL = 0 ] && rm -f \$lockfile
    return \$RETVAL
}

case "\$1" in
    start)
    start
    ;;
    stop)
    stop
    ;;
    restart)
    stop
    start
    ;;
    status)
    status \$lsyncd
    ;;
    *)

    echo "Usage: lsyncd {start|stop|restart|status}"
    exit 1
esac

exit \$?
EOF
# Turn on at boot
/sbin/chkconfig lsyncd on
fi

# Set proper permissions/ownership on init scripts
/bin/chmod 775 /etc/init.d/lsyncd
/bin/chown root:root /etc/init.d/lsyncd
# Create log directory
if [ ! -d /var/log/lsyncd ]; then
    /bin/mkdir /var/log/lsyncd
fi

# Create logrotate script (Distro-agnostic)
cat > /etc/logrotate.d/lsyncd << EOF
/var/log/lsyncd/*log {
    missingok
    notifempty
    sharedscripts
    postrotate

        /etc/init.d/lsyncd restart &> /dev/null || true

    endscript
}
EOF

# Create basic lsyncd configuration file
cat > /etc/lsyncd.lau << EOF
settings = {
   logfile    = "/var/log/lsyncd/lsyncd.log",
   statusFile = "/var/log/lsyncd/lsyncd-status.log",
   statusInterval = 20

}

EOF

# Iterate through SYNC_HOSTS array
# and create appropriate sync block for each
for HOST in ${SYNC_HOSTS[*]}; do
    cat >> /etc/lsyncd.lau << EOF
sync {
    default.rsyncssh,
    source="${SYNC_SOURCE}",
    host="${HOST}",
    targetdir="${SYNC_TARGET}",
    rsyncOpts="-avz"
}

EOF
done
pass "${OUTPUT}"

# Start the service
OUTPUT="Starting lsyncd service..."
printf "$OUTPUT"
/etc/init.d/lsyncd start &> /dev/null || die $OUTPUT
pass "${OUTPUT}"

echo
echo "Ding! Fries are done. Now install SSH keys and rsync on the slaves."
echo "${red}NOTE:${normal} Lsyncd 2.0.5+ will gracefully quit if it cannot rsync to the destination servers."
