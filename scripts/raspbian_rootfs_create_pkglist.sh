#!/bin/sh
# Author : https://github.com/ft128/libzwaveip/
# Purpose: This script create a raspbian_rootfs_<RASPBIAN_CODENAME>.pkglist
#        : file listing all the deb packages for cross compiling libzwaveip only.
# Usage  : pi@raspberrypi$ ./raspbian_rootfs_create_pkglist.sh

distro_rootfs_create_pkglist() {
	local DISTRO_ID_REQUIRED
	local DISTRO_VERSION
	local DISTRO_ID
	local DEB_REPOSITORY_URL
	local DISTRO_CODENAME

	DISTRO_ID_REQUIRED="$1"
	if [ -f /etc/os-release ]; then
		DISTRO_VERSION=$(grep "^VERSION=" /etc/os-release | sed -e 's,.*=,,' | sed -e 's/^[ \t]*//' | sed 's,",,g')
		DISTRO_ID=$(grep "^ID=" /etc/os-release | sed -e 's,.*=,,' | sed -e 's/^[ \t]*//' | sed 's,",,g')
		if [ "x${DISTRO_ID}" != "x${DISTRO_ID_REQUIRED}" ]; then
			echo "ERROR: Please run this script on ${DISTRO_ID_REQUIRED} system."
			exit 1
		fi

		DEB_REPOSITORY_URL="http://archive.raspbian.org/raspbian"
		echo "DISTRO_VERSION=${DISTRO_VERSION}"
		if [ "x${DISTRO_VERSION}" = "x8 (jessie)" ]; then
			DISTRO_CODENAME="jessie"
			apt-cache show \
				libc6 libc6-dev linux-libc-dev libc-bin libusb-1.0-0 libusb-1.0-0-dev libudev1 \
				libxml2 libxml2-dev zlib1g zlib1g-dev liblzma5 liblzma-dev \
				libssl1.0.0 libssl-dev libbsd0 libbsd-dev libncurses5 libncurses5-dev \
				libtinfo5 libtinfo-dev libavahi-client3 libavahi-client-dev libavahi-common3 \
				libavahi-common-dev libdbus-1-3 libdbus-1-dev \
				| grep "^Filename:" | sed 's/^Filename:[ \t\/]*//g' | sed -e "s,^,${DEB_REPOSITORY_URL}/," > ${DISTRO_ID_REQUIRED}_rootfs_${DISTRO_CODENAME}.pkglist
				cat ${DISTRO_ID_REQUIRED}_rootfs_${DISTRO_CODENAME}.pkglist
		elif [ "x${DISTRO_VERSION}" = "x9 (stretch)" ]; then
			DISTRO_CODENAME="stretch"
			apt-cache show \
				libc6 libc6-dev linux-libc-dev libc-bin libusb-1.0-0 libusb-1.0-0-dev libudev1 \
				libxml2 libxml2-dev zlib1g zlib1g-dev liblzma5 liblzma-dev \
				libssl1.0.2 libssl1.0-dev libbsd0 libbsd-dev libncurses5 libncurses5-dev \
				libtinfo5 libtinfo-dev libavahi-client3 libavahi-client-dev libavahi-common3 \
				libavahi-common-dev libdbus-1-3 libdbus-1-dev \
				libicu57 libicu-dev libstdc++6 libsystemd0 libselinux1 liblz4-1 libgcrypt20 \
				libpcre3 libgpg-error0 \
				| grep "^Filename:" | sed 's/^Filename:[ \t\/]*//g' | sed -e "s,^,${DEB_REPOSITORY_URL}/," > ${DISTRO_ID_REQUIRED}_rootfs_${DISTRO_CODENAME}.pkglist
				cat ${DISTRO_ID_REQUIRED}_rootfs_${DISTRO_CODENAME}.pkglist
		else
			echo "ERROR: Unknown OS Release."
			exit 1
		fi
	else
		echo "ERROR: /etc/os-release file not found."
		exit 1
	fi
}

distro_rootfs_create_pkglist "raspbian"
