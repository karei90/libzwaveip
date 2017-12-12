#!/bin/sh
# Author : https://github.com/ft128/libzwaveip/
# Purpose: Installing Linaro ARM toolchain and Raspbian Linux deb packages on x86 PC
#        : for cross compiling libzwaveip only.
#        : Also see file: cmake/linaro-toolchain.cmake
# Usage  : user@UbuntuPC$ sudo ./scripts/install-linaro-toolchain.sh

INSTALL_PATH="/opt/linaro"
TARGET_ROOTFS="${INSTALL_PATH}/raspbian_rootfs"
TOOLCHAIN_SYMLINK_DIR="${INSTALL_PATH}/gcc-linaro-arm-linux-gnueabihf"

# Download deb files and extract to target rootfs directory
func_download_extract_raspbian_packages() {
	local DEB_REPOSITORY_URL
	local DEB_URL_SCHEME
	local DEB_PACKAGES
	local DEB
	local DEB_DIRNAME
	local DEB_BASENAME
	local DEB_SAVED_FILENAME
	local RASPBIAN_PACKAGES_DIR
	local RETVAL

	DEB_PACKAGES="$1"

	#DEB_REPOSITORY_URL="http://mirrordirector.raspbian.org/raspbian"
	DEB_REPOSITORY_URL="http://archive.raspbian.org/raspbian"
	RASPBIAN_PACKAGES_DIR="${INSTALL_PATH}/raspbian_packages"
	mkdir -p ${TARGET_ROOTFS}
	mkdir -p "${RASPBIAN_PACKAGES_DIR}"
	for DEB in ${DEB_PACKAGES}; do
		# Check for any URI in DEB, get the scheme
		DEB_URL_SCHEME=$(echo ${DEB} | grep -E "^[a-z]{3,5}:\/\/")
		# Remove URI scheme if any.
		DEB_DIRNAME=$(dirname ${DEB} | sed 's|^.*:\/\/||g')
		DEB_BASENAME=$(basename ${DEB})
		mkdir -p "${RASPBIAN_PACKAGES_DIR}/${DEB_DIRNAME}"
		if [ ! -f "${RASPBIAN_PACKAGES_DIR}/${DEB_DIRNAME}/${DEB_BASENAME}" ]; then
			echo "Download, cache and extract: ${DEB}"
			if [ "x${DEB_URL_SCHEME}" = "x" ]; then
				# No URI scheme. Add default download URL
				DEB_SAVED_FILENAME="${DEB_REPOSITORY_URL}/${DEB}"
				wget -q -nv -c -P "${RASPBIAN_PACKAGES_DIR}/${DEB_DIRNAME}" -O "${DEB_SAVED_FILENAME}.download" "${DEB_REPOSITORY_URL}/${DEB}"
				RETVAL=$?
			else
				# With URI scheme, this will capable to download from different repositories.
				DEB_SAVED_FILENAME="${RASPBIAN_PACKAGES_DIR}/${DEB_DIRNAME}/${DEB_BASENAME}"
				wget -q -nv -c -P "${RASPBIAN_PACKAGES_DIR}/${DEB_DIRNAME}" -O "${DEB_SAVED_FILENAME}.download" "${DEB}"
				RETVAL=$?
			fi

			if [ "x${RETVAL}" = "x0" ]; then
				mv -f "${DEB_SAVED_FILENAME}.download" "${DEB_SAVED_FILENAME}"
				dpkg -x "${DEB_SAVED_FILENAME}" "${TARGET_ROOTFS}"
			else
				echo "ERROR: Fail to download ${DEB_BASENAME}."
			fi
		else
			echo "Extract from cache: ${DEB}"
			dpkg -x "${RASPBIAN_PACKAGES_DIR}/${DEB_DIRNAME}/${DEB_BASENAME}" "${TARGET_ROOTFS}"
		fi
	done
}

# Fix absolute symbolic link to relative symbolic link in target rootfs
# Fix symbolic link to link in target rootfs.
func_fix_target_rootfs_symlink() {
	local LINK_NAME
	local ORIGINAL_LINK_TARGET
	local ORIGINAL_LINK_TARGET_MOD

	LINK_NAME="$1"
	if [ -h ${LINK_NAME} ]; then
		ORIGINAL_LINK_TARGET=$(readlink ${LINK_NAME})
		#echo "LinkTarget:${ORIGINAL_LINK_TARGET}  LinkName:${LINK_NAME}"
		ORIGINAL_LINK_TARGET_MOD=$(echo "${ORIGINAL_LINK_TARGET}" | sed 's/^\.\///' | sed 's/^\///')
		if [ -e "${TARGET_ROOTFS}/${ORIGINAL_LINK_TARGET_MOD}" ]; then
			ln -sf "${TARGET_ROOTFS}/${ORIGINAL_LINK_TARGET_MOD}"  "${LINK_NAME}"
		fi
	else
		echo "ERROR: ${LINK_NAME} not exist."
	fi
}

# Clean target rootfs
install_fresh_target_rootfs() {
	rm -fr ${TARGET_ROOTFS}
}

# Install arm-linux-gnueabihf-ldd
install_crosstool_ng_ldd() {
	local CT_VERSION="origin/master"
	local CT_TARGET="arm-linux-gnueabihf"
	local CT_ARCH_BITNESS="32"
	local bash="/bin/bash"

	# Install 'arm-linux-gnueabihf-ldd' script
	wget -nv -c -O /tmp/xldd.in https://raw.githubusercontent.com/crosstool-ng/crosstool-ng/master/scripts/xldd.in
	sed -r -e 's|@@CT_VERSION@@|'"${CT_VERSION}"'|g;'   \
		   -e 's|@@CT_TARGET@@|'"${CT_TARGET}"'|g;'     \
		   -e 's|@@CT_BITS@@|'"${CT_ARCH_BITNESS}"'|g;' \
		   -e 's|@@CT_install@@|'"install"'|g;'         \
		   -e 's|@@CT_bash@@|'"${bash}"'|g;'            \
		   -e 's|@@CT_grep@@|'"grep"'|g;'               \
		   -e 's|@@CT_make@@|'"make"'|g;'               \
		   -e 's|@@CT_sed@@|'"sed"'|g;'                 \
		   "/tmp/xldd.in"                               \
		   > "/tmp/${CT_TARGET}-ldd"
	chmod 755 "/tmp/${CT_TARGET}-ldd"
	# Uncomment if you want to hard code the --root path in 'arm-linux-gnueabihf-ldd' script
	#sed -i '/^root="\${CT_XLDD_ROOT}"/i CT_XLDD_ROOT="'"${TARGET_ROOTFS}"'"' "/tmp/${CT_TARGET}-ldd"
	mv -f "/tmp/${CT_TARGET}-ldd" "${TOOLCHAIN_SYMLINK_DIR}/bin/${CT_TARGET}-ldd"

	# fix arm-linux-gnueabihf-ldd dependencies /etc/ld.so.conf, if libc-bin is not installed
	if [ ! -f "${TARGET_ROOTFS}/etc/ld.so.conf" ]; then
		mkdir -p ${TARGET_ROOTFS}/etc/
		sh -c "echo 'include /etc/ld.so.conf.d/*.conf' > ${TARGET_ROOTFS}/etc/ld.so.conf"
	fi
	if [ ! -f "${TARGET_ROOTFS}/etc/ld.so.conf.d/arm-linux-gnueabihf.conf" ]; then
		mkdir -p ${TARGET_ROOTFS}/etc/ld.so.conf.d
		sh -c "echo '# Multiarch support' > ${TARGET_ROOTFS}/etc/ld.so.conf.d/arm-linux-gnueabihf.conf"
		sh -c "echo '/lib/arm-linux-gnueabihf' >> ${TARGET_ROOTFS}/etc/ld.so.conf.d/arm-linux-gnueabihf.conf"
		sh -c "echo '/usr/lib/arm-linux-gnueabihf' >> ${TARGET_ROOTFS}/etc/ld.so.conf.d/arm-linux-gnueabihf.conf"
	fi
}

# Install ARM cross compiler from linaro.org
install_linaro_cross_compiler() {
	local OS_32BIT_64BIT
	local TOOLCHAIN
	local TOOLCHAIN_DOWNLOAD_URL
	local LINARO_PACKAGES_DIR
	local RETVAL

	OS_32BIT_64BIT=$(uname -m)
	if [ "${OS_32BIT_64BIT}" = "x86_64" ]; then
		# gcc build with: --with-tune=cortex-a9 --with-arch=armv7-a --with-fpu=vfpv3-d16 --with-float=hard --with-mode=thumb
		TOOLCHAIN="gcc-linaro-6.4.1-2017.11-x86_64_arm-linux-gnueabihf"
	else
		# gcc build with: --with-tune=cortex-a9 --with-arch=armv7-a --with-fpu=vfpv3-d16 --with-float=hard --with-mode=thumb
		TOOLCHAIN="gcc-linaro-6.4.1-2017.11-i686_arm-linux-gnueabihf"
	fi
	TOOLCHAIN_DOWNLOAD_URL="https://releases.linaro.org/components/toolchain/binaries/6.4-2017.11/arm-linux-gnueabihf/${TOOLCHAIN}.tar.xz"

	LINARO_PACKAGES_DIR="${INSTALL_PATH}/linaro_packages"
	rm -fr ${INSTALL_PATH}/${TOOLCHAIN}
	mkdir -p "${LINARO_PACKAGES_DIR}"
	if [ ! -f "${LINARO_PACKAGES_DIR}/${TOOLCHAIN}.tar.xz" ]; then
		echo "Download, cache and extract: ${TOOLCHAIN}.tar.xz"
		wget -nv -c -O "${LINARO_PACKAGES_DIR}/${TOOLCHAIN}.tar.xz.download" "${TOOLCHAIN_DOWNLOAD_URL}"
		RETVAL=$?
		if [ "x${RETVAL}" = "x0" ]; then
			mv -f "${LINARO_PACKAGES_DIR}/${TOOLCHAIN}.tar.xz.download" "${LINARO_PACKAGES_DIR}/${TOOLCHAIN}.tar.xz"
			tar -C ${INSTALL_PATH} --xz -xf "${LINARO_PACKAGES_DIR}/${TOOLCHAIN}.tar.xz"
		fi
	else
		echo "Extract from cache: ${TOOLCHAIN}.tar.xz"
		tar -C ${INSTALL_PATH} --xz -xf "${LINARO_PACKAGES_DIR}/${TOOLCHAIN}.tar.xz"
	fi

	chown -R root:root ${INSTALL_PATH}/${TOOLCHAIN}
	unlink ${TOOLCHAIN_SYMLINK_DIR} > /dev/null 2>&1
	ln -sf ${TOOLCHAIN} ${TOOLCHAIN_SYMLINK_DIR}
	echo "Symlink: ln -sf ${TOOLCHAIN} ${TOOLCHAIN_SYMLINK_DIR}"

	install_crosstool_ng_ldd
}

# Install ARM cross compiler from github.com/raspberrypi/tools.git
install_github_raspberrypi_tools_cross_compiler() {
	local RPI_TOOLS_DIR
	local OS_32BIT_64BIT
	local TOOLCHAIN

	# See: https://github.com/raspberrypi/tools/issues/50
	RPI_TOOLS_DIR="${INSTALL_PATH}/raspberrypi_tools"
	if [ ! -f "${RPI_TOOLS_DIR}/.git/index" ]; then
		echo "git clone https://github.com/raspberrypi/tools.git"
		git clone https://github.com/raspberrypi/tools.git ${RPI_TOOLS_DIR}
	else
		echo "git pull https://github.com/raspberrypi/tools.git"
		git -C "${RPI_TOOLS_DIR}" clean -dfx
		git -C "${RPI_TOOLS_DIR}" reset --hard
		git -C "${RPI_TOOLS_DIR}" pull
	fi

	OS_32BIT_64BIT=$(uname -m)
	if [ "${OS_32BIT_64BIT}" = "x86_64" ]; then
		if [ -f "${RPI_TOOLS_DIR}/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc" ]; then
			# gcc build with: --with-arch=armv6 --with-fpu=vfp --with-float=hard
			TOOLCHAIN="${RPI_TOOLS_DIR}/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf"

			unlink ${TOOLCHAIN_SYMLINK_DIR} > /dev/null 2>&1
			ln -sf ${TOOLCHAIN} ${TOOLCHAIN_SYMLINK_DIR}
			echo "Symlink: ln -sf ${TOOLCHAIN} ${TOOLCHAIN_SYMLINK_DIR}"
		fi

		# Specific dirty fixes for arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf
		# See: https://github.com/Kukkimonsuta/rpi-buildqt/blob/master/scripts/2_sync.sh
		unlink ${TARGET_ROOTFS}/lib/arm-linux-gnueabihf/4.9.3 > /dev/null 2>&1
		ln -sf . ${TARGET_ROOTFS}/lib/arm-linux-gnueabihf/4.9.3
		unlink ${TARGET_ROOTFS}/usr/lib/arm-linux-gnueabihf/4.9.3 > /dev/null 2>&1
		ln -sf . ${TARGET_ROOTFS}/usr/lib/arm-linux-gnueabihf/4.9.3
	else
		echo "32bit Linux OS is not suitable for arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf"
	fi
}

# Install Raspbian deb packages to create target rootfs
install_raspbian_target_rootfs() {
	local DEB_PACKAGES
	local BROKEN_SYMLINK
	local RASPBIAN_RELEASE_ROOTFS_PKGLIST
	local SCRIPT_PATH
	local DO_INSTALL_PKGLIST
	local DO_SYMLINK_FIX

	RASPBIAN_RELEASE_ROOTFS_PKGLIST="$1"
	SCRIPT_PATH="$(dirname $0)"
	DO_INSTALL_PKGLIST="yes"
	DO_SYMLINK_FIX="yes"

	if [ "x${DO_INSTALL_PKGLIST}" = "xyes" ]; then
		if [ ! -f "${SCRIPT_PATH}/${RASPBIAN_RELEASE_ROOTFS_PKGLIST}.pkglist" ]; then
			echo "ERROR: ${SCRIPT_PATH}/${RASPBIAN_RELEASE_ROOTFS_PKGLIST}.pkglist not found."
			exit
		else
			echo "INFO: Creating ${RASPBIAN_RELEASE_ROOTFS_PKGLIST} ${TARGET_ROOTFS}"
			for DEB_PACKAGES in $(cat "${SCRIPT_PATH}/${RASPBIAN_RELEASE_ROOTFS_PKGLIST}.pkglist"); do
				DEB_PACKAGES=$(echo "${DEB_PACKAGES}" | grep -vxE '[[:blank:]]*([#;].*)?' | sed -e 's/^[ \t]*//' | sed -e 's/\s\s*/ /g')
				if [ "x${DEB_PACKAGES}" != "x" ]; then
					func_download_extract_raspbian_packages "${DEB_PACKAGES}"
				fi
			done
		fi
	fi

	if [ "x${DO_SYMLINK_FIX}" = "xyes" ]; then
		if [ ! -f "${SCRIPT_PATH}/${RASPBIAN_RELEASE_ROOTFS_PKGLIST}_symlink.fix" ]; then
			echo "ERROR: ${SCRIPT_PATH}/${RASPBIAN_RELEASE_ROOTFS_PKGLIST}_symlink.fix not found."
			exit
		else
			for BROKEN_SYMLINK in $(cat "${SCRIPT_PATH}/${RASPBIAN_RELEASE_ROOTFS_PKGLIST}_symlink.fix"); do
				BROKEN_SYMLINK=$(echo "${BROKEN_SYMLINK}" | grep -vxE '[[:blank:]]*([#;].*)?' | sed -e 's/^[ \t]*//' | sed -e 's/\s\s*/ /g')
				if [ "x${BROKEN_SYMLINK}" != "x" ]; then
					func_fix_target_rootfs_symlink "${TARGET_ROOTFS}/${BROKEN_SYMLINK}"
				fi
			done
		fi
	fi
}

# Check any broken symbolic link
install_check_any_broken_symlink() {
	local BROKEN_LINKS

	BROKEN_LINKS=$(find ${TARGET_ROOTFS} -xtype l)
	if [ "x${BROKEN_LINKS}" != "x" ]; then
		echo "List of broken symbolic links:"
		find ${TARGET_ROOTFS} -xtype l
	fi
}


USE_CROSS_COMPILER="github_raspberrypi_tools"
USE_DISTRO_ROOTFS_PKGLIST="raspbian_rootfs_jessie"

install_fresh_target_rootfs
install_raspbian_target_rootfs "${USE_DISTRO_ROOTFS_PKGLIST}"
if [ "x${USE_CROSS_COMPILER}" = "xgithub_raspberrypi_tools" ]; then
	install_github_raspberrypi_tools_cross_compiler
elif [ "x${USE_CROSS_COMPILER}" = "xlinaro_toolchain" ]; then
	install_linaro_cross_compiler
else
	echo "INFO: You need to prepare ARM cross compiler."
	echo "INFO: Example: For Ubuntu system, run: sudo apt-get install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf"
fi
install_check_any_broken_symlink
