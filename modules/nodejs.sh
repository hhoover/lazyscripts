#!/bin/bash
## Node.js Installation Script
## Author: David Wittman <david@wittman.com>

SOURCE="http://nodejs.org/dist/v0.6.1/node-v0.6.1.tar.gz"
SOURCEPATH="/usr/local/src/"

bold=$(tput bold)
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)

begin() {
	OUTPUT="[*] $*"
	printf "${OUTPUT}"	
}

pass() {
	local COLUMNS=$(tput cols)
	echo "$1" | awk -v width=${COLUMNS} '{ padding=(width-length($0)-8); printf "%"(padding)"s", "[  ";}'
	echo -e "${bold}${green}OK${normal}  ]"
}

die() {
	# Usage: /path/to/command || die "This shit didn't work"
	local COLUMNS=$(tput cols)
	echo "$1" | awk -v width=${COLUMNS} '{ padding=(width-length($0)-9); printf "%"(padding)"s", "[ ";}'
	echo -e "${bold}${red}FAIL${normal} ]"
	exit 1
}

detect_os() {
	if [[ "${distro}" == "Redhat/CentOS" || "${distro}" == "Ubuntu" ]]; then
		echo "${bold}${distro}${normal} detected."
	else
		begin "Unknown distribution or missing 'distro' environment variable."
		die "${OUTPUT}"
	fi
}

sourceinstall() {
        local BASENAME=$(basename "${1}")
        local SOURCEDIR="${SOURCEPATH}$(echo ${BASENAME} | sed 's/\.tar\.gz//')"
        local GET="/usr/bin/wget --quiet"
        local MAKE="/usr/bin/make"

        # Download and untar
        begin "Downloading and extracting..."
        ${GET} "${1}" || die "$OUTPUT"
        if [ -d ${SOURCEDIR} ]; then
                rm -rf ${SOURCEDIR}
        fi
        /bin/mkdir ${SOURCEDIR} || die "$OUTPUT"
        /bin/tar --strip 1 -xf ${BASENAME} -C ${SOURCEDIR} || die "$OUTPUT"
        /bin/rm ${BASENAME}
        pass "$OUTPUT"

        # Compile and install
        begin "Compiling and installing..."
        cd ${SOURCEDIR}
        ./configure &> /dev/null || die "$OUTPUT"
        ${MAKE} -j5 &> /dev/null && ${MAKE} install &> /dev/null || die "$OUTPUT"

        pass "${OUTPUT}"
}

install_deps() {
	if [[ $distro == "Redhat/CentOS" ]]; then
		local INSTALL="/usr/bin/yum -qy install"
		local DEPS="gcc-c++ make git openssl-devel"
	elif [[ $distro == "Ubuntu" ]]; then
		local INSTALL="/usr/bin/apt-get install -yq"
		local DEPS="build-essential git-core libssl-dev"
	fi

	begin "Installing dependencies..."
	${INSTALL} ${DEPS} > /dev/null || die "${OUTPUT}"
	pass "${OUTPUT}"
}

install_npm() {
	local REPO="https://github.com/isaacs/npm.git"
	local SOURCEDIR="${SOURCEPATH}npm"
	export GIT_SSL_NO_VERIFY=true

	begin "Installing Node Package Manager..."
	git clone https://github.com/isaacs/npm.git ${SOURCEDIR} &> /dev/null && cd ${SOURCEDIR} || die
	curl -s http://npmjs.org/install.sh 2> /dev/null | sh &> /dev/null || die
	pass "${OUTPUT}"
}

# Main thread
detect_os
install_deps
sourceinstall ${SOURCE}
install_npm

echo "Node.js $(node -v) has successfully been installed."
