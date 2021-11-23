#!/bin/bash

# setting working directory
WORK_DIR="/home/user"

# setting branch
if [ "${OPENWRT_BRANCH}" = "" ]
then
	DEFAULT_OPENWRT_BRANCH="openwrt-21.02"
else
	DEFAULT_OPENWRT_BRANCH="${OPENWRT_BRANCH}"
fi

download_openwrt() {
	cd ${WORK_DIR}

	# pull code
	if [ ! -d "openwrt" ]; then
  		git clone https://git.openwrt.org/openwrt/openwrt.git	
	fi
}

change_openwrt_branch() {
	cd ${WORK_DIR}/openwrt

	if [ "${1}" = "" ]
	then
		echo "Building ${DEFAULT_OPENWRT_BRANCH}"
		git checkout -B ${DEFAULT_OPENWRT_BRANCH} origin/${DEFAULT_OPENWRT_BRANCH}
	else
		echo "Building ${1}"
		git checkout -B ${1} origin/${1}
	fi
}

init_openwrt_branch() {
	cd ${WORK_DIR}/openwrt

	git stash
	git pull --all
	git pull --tags
}

init_openwrt_link() {
	cd ${WORK_DIR}/openwrt

	sudo chown 1000:1000 /src -R

	mkdir -p /src/dl
	mkdir -p /src/staging_dir
	mkdir -p /src/build_dir
	mkdir -p /src/tmp

	ln -s /src/dl ${WORK_DIR}/openwrt/dl
	ln -s /src/staging_dir ${WORK_DIR}/openwrt/staging_dir
	ln -s /src/build_dir ${WORK_DIR}/openwrt/build_dir
	ln -s /src/tmp ${WORK_DIR}/openwrt/tmp
}

update_install_openwrt_feeds() {
	cd ${WORK_DIR}/openwrt

	./scripts/feeds update -a
	./scripts/feeds install -a
}

openwrt_init_config() {
	cd ${WORK_DIR}/openwrt

	echo "CONFIG_TARGET_x86=y" > ${WORK_DIR}/openwrt/.config
	echo "CONFIG_TARGET_x86_64=y" >> ${WORK_DIR}/openwrt/.config
}

openwrt_make_build_env() {
	cd ${WORK_DIR}/openwrt

	make defconfig
	make -j4 download
 	make -j4 tools/install
 	make -j4 toolchain/install
}

openwrt_make() {
	cd ${WORK_DIR}/openwrt

	make -j4
}

openwrt_install_netmaker_feeds() {
	cd ${WORK_DIR}/openwrt

	echo "src-git netmaker http://github.com/sbilly/netmaker-openwrt.git" >> feeds.conf.default

	./scripts/feeds update netmaker
	./scripts/feeds install netmaker
}

openwrt_make_package() {
	cd ${WORK_DIR}/openwrt

	if [ "${1}" = "" ]
	then
		make package/${1}/clean
		find ./ -type d | xargs -n1 sudo chmod 755 -R
		make package/${1}/compile
	fi
}

openwrt_install_package_netmaker_config() {
	cd ${WORK_DIR}/openwrt

	echo "CONFIG_FEED_netmaker=y" >> ${WORK_DIR}/openwrt/.config
	echo "CONFIG_PACKAGE_netmaker=m" >> ${WORK_DIR}/openwrt/.config
	echo "CONFIG_PACKAGE_netmaker-dev=m" >> ${WORK_DIR}/openwrt/.config
}


openwrt_make_netmaker_package() {
	cd ${WORK_DIR}/openwrt

	make package/netmaker/clean
	find ./ -type d | xargs -n1 sudo chmod 755 -R
	make package/netmaker/compile
}


download_openwrt

change_openwrt_branch ${DEFAULT_OPENWRT_BRANCH}

init_openwrt_branch

init_openwrt_link

openwrt_install_netmaker_feeds

update_install_openwrt_feeds

openwrt_init_config

openwrt_install_package_netmaker_config

openwrt_make_netmaker_package

ls -alF ${WORK_DIR}/openwrt/bin/
