#
# Build the Orbit PXE kernel image and initramfs
#
NAME = omf-pxe
VER = 5.4

OMF_RELEASE=5.4
DEB_REP=debian
KORG_URL = http://mirror.aarnet.edu.au/pub/ftp.kernel.org/linux/kernel/v
KERNEL_VERSION = 3
KERNEL_PATCHLEVEL = 0
KERNEL_SUBLEVEL = 4
KERNEL_EXTRAVERSION = 
KERNEL_MAIN_VER=$(KERNEL_VERSION).$(KERNEL_PATCHLEVEL).$(KERNEL_SUBLEVEL)
KVER = $(KERNEL_MAIN_VER)$(KERNEL_EXTRAVERSION)
KERNEL_DIR = linux-$(KVER)
KERNEL_TAR = $(KERNEL_DIR).tar.gz
KERNEL_BASE_URL = $(KORG_URL)$(KERNEL_VERSION).$(KERNEL_PATCHLEVEL)
KERNEL_TAR_URL = $(KERNEL_BASE_URL)/$(KERNEL_TAR)
KERNEL_NAME = linux-$(NAME)-$(KVER)
BBOX_VERSION = 1.16.1
BBOX_DIR = busybox-$(BBOX_VERSION)
BBOX_TAR = busybox-$(BBOX_VERSION).tar.bz2
BBOX_URL = http://busybox.net/downloads
BBOX_TAR_URL = $(BBOX_URL)/$(BBOX_TAR)
KERNEL_BUILD_JOBS = $(shell grep "^processor" /proc/cpuinfo | wc -l)
LBITS = $(shell getconf LONG_BIT)

# --------  START OF SITE DEPENDENT VARIABLES ---------
#  In order to make this work for users outside of Winlab, the site
#  dependent variables are collected here. These allow you to redefine
#  a local package server, and local config files for kernel and busybox.
#
#  They may be definied in ENV VARS, or in an include file, if present.
#  The default values here are for winlab.
#
#  THEREFORE, in summary:
#  * If you are building for Winlab, edit the right hand side
#    of the following expressions.
#  * If you are not building for Winlab, edit ./site.mk.
#     (follow the example "nicta.mk")
#

-include ./site.mk
APT_HOST ?= http://apt
REPOSITORY ?= $(USER)@repository1
REPOSITORY_ROOT ?= /export/web/orbit/dists/testing/main
WINLAB_REP ?= winlab/binary
MAIN_REP ?= orbit/dists/testing/main/binary-i386
KERNEL_CONFIG_FILE ?= $(KERNEL_NAME).config
BBOX_CONFIG_FILE ?= $(BBOX_DIR).config
# --------  END OF SITE DEPENDENT VARIABLES ---------

INITRAMFS = initramfs-$(NAME)-$(VER)
INITRAMFSGZ = $(INITRAMFS).gz
INITRAMFS_LIST = $(INITRAMFS).list


GETMAC_DIR= getmac-1.0

PXE_PATH=/usr/lib/syslinux/
PXE_SRC=pxelinux.0
PXE_DST=pxelinux.bin

TFTP_DIR = /tftpboot
CFG_DIR = $(TFTP_DIR)/pxelinux.cfg

# Where we get our build config files from
CONFIG = config
# Where the kernel and initramfs end up
BUILD = build
# What we'll build our initramfs rootfs from
ROOTFS = rootfs
# Where the tars are dl'ed and extracted
SOURCE = src
# Dump temp data
TEMP = tmp

LIB =	/lib/i386-linux-gnu/ld-linux.so.2 /lib/i386-linux-gnu/libc.so.6 /lib/i386-linux-gnu/libm.so.6 /lib/i386-linux-gnu/libpthread.so.0 
LIB +=	/lib/i386-linux-gnu/libdl.so.2 /lib/i386-linux-gnu/libcrypt.so.1 /lib/libnih.so.1 /lib/libnih-dbus.so.1
LIB +=	/lib/i386-linux-gnu/libnss_dns.so.2 /lib/i386-linux-gnu/libresolv.so.2
# Currently nodeagent requires lspci, which requires libpci. Remove this 
# if not needed.
LIB += /lib/libpci.so.3
# for ruby1.8
LIB +=  /lib/i386-linux-gnu/librt.so.1

#all: apt-get-update kernel initramfs
all: kernel initramfs

apt-get-update:
	sudo apt-get update

dirs:
	if [ $(LBITS) != 32 ] ; then \
	  echo "The OMF PXE image can only be built on a 32bit host at this time."; \
          false; \
	fi
	install -d $(BUILD) $(ROOTFS) $(SOURCE) $(TEMP)

bbox: 	get_bbox
	if [ ! -r $(SOURCE)/$(BBOX_DIR) ] ; then \
	  tar -xjf $(SOURCE)/$(BBOX_TAR) -C $(SOURCE); \
	fi
	cp $(CONFIG)/$(BBOX_CONFIG_FILE) $(SOURCE)/$(BBOX_DIR)/.config
	sed 's|CONFIG_PREFIX=.*|CONFIG_PREFIX=\"../../$(ROOTFS)/\"|'  \
	  $(CONFIG)/$(BBOX_CONFIG_FILE) > $(SOURCE)/$(BBOX_DIR)/.config
	$(MAKE) -C $(SOURCE)/$(BBOX_DIR) install

omf:
	sudo apt-get clean; sudo apt-get update
	apt-get -d --reinstall --force-yes -y --print-uris install omf-common-$(OMF_RELEASE) omf-resctl-$(OMF_RELEASE) ruby1.8 libruby1.8 libopenssl-ruby1.8 bash libncurses5 frisbee imagezip zlib1g libssl1.0.0 libgcc1 syslinux kexec-tools netcat-traditional libdbus-1-3 e2fsprogs libcomerr2 libblkid1 libuuid1 e2fslibs util-linux libusb-1.0-0 usbutils rubygems libtinfo5 | grep http | awk '{print $$1}' | tr -d "'" > $(TEMP)/omf-packages
	mkdir -p $(SOURCE)/omf; cd $(SOURCE)/omf; rm *.deb; wget -N -i ../../$(TEMP)/omf-packages
	for file in `ls $(SOURCE)/omf/*.deb`; do dpkg -x $$file $(ROOTFS); done
	mv $(ROOTFS)/bin/nc.traditional $(ROOTFS)/bin/nc
	cp $(ROOTFS)/usr/share/doc/omf-resctl-$(OMF_RELEASE)/examples/omf-resctl.nicta.yaml $(ROOTFS)/etc/omf-resctl-$(OMF_RELEASE)/omf-resctl.yaml
	sed -i 's/OMF_RELEASE/$(OMF_RELEASE)/g' $(ROOTFS)/etc/init.d/rcS.actual
	(cd $(ROOTFS)/usr/share/omf-common-$(OMF_RELEASE)/gems/1.8; GEM_PATH=$PWD gem install --no-ri --no-rdoc -l -f -i . cache/*.gem)
	ln -sf ruby1.8 $(ROOTFS)/usr/bin/ruby
syslinux: omf
	for file in `ls $(SOURCE)/omf/syslinux*`; do dpkg -x $$file $(TEMP); done
	install -m 755 $(TEMP)/$(PXE_PATH)/$(PXE_SRC)  $(BUILD)/$(PXE_DST)

getmac:
	make -C $(GETMAC_DIR)/ install DESTDIR=$(CURDIR)/$(ROOTFS)/

enroll:
	install --mode=770 $(CONFIG)/enroll $(ROOTFS)/dev/

kexec: omf
	dpkg -x $(SOURCE)/omf/kexec* $(ROOTFS)

filesystem: dirs
	install -d $(ROOTFS)/tmp
	install -d $(ROOTFS)/var
	install -d $(ROOTFS)/var/log
	install -d $(ROOTFS)/log
	install -d $(ROOTFS)/var/run
	install -d $(ROOTFS)/var/lib
	install -d $(ROOTFS)/lib
	install -d $(ROOTFS)/sbin
	sudo apt-get install pciutils 
	install $(LIB) $(ROOTFS)/lib
	install -d $(ROOTFS)/etc
	install -d $(ROOTFS)/etc/init.d
	install -d $(ROOTFS)/proc
	install -d $(ROOTFS)/dev
	-sudo mknod -m 666 $(ROOTFS)/dev/urandom c 1 9
	-sudo mknod -m 660 $(ROOTFS)/dev/console c 5 1
	-sudo mknod -m 666 $(ROOTFS)/dev/null c 1 3
	-sudo mknod -m 666 $(ROOTFS)/dev/tty0 c 4 0
	-sudo mknod -m 666 $(ROOTFS)/dev/tty1 c 4 1
	-sudo mknod -m 666 $(ROOTFS)/dev/tty2 c 4 2
	-sudo mknod -m 666 $(ROOTFS)/dev/tty3 c 4 3
	-sudo mknod -m 666 $(ROOTFS)/dev/tty4 c 4 4
	-sudo mknod -m 600 $(ROOTFS)/dev/ttyS0 c 4 64
	-sudo mknod -m 600 $(ROOTFS)/dev/ttyp0 c 3 0
	-sudo mknod -m 620 $(ROOTFS)/dev/ptmx c 5 2
	-sudo mknod -m 660 $(ROOTFS)/dev/hda b 3 0
	-sudo mknod -m 660 $(ROOTFS)/dev/hda1 b 3 1
	-sudo mknod -m 660 $(ROOTFS)/dev/hda2 b 3 2
	-sudo mknod -m 660 $(ROOTFS)/dev/hda3 b 3 3
	-sudo mknod -m 660 $(ROOTFS)/dev/sda b 8 0
	-sudo mknod -m 660 $(ROOTFS)/dev/sda1 b 8 1
	-sudo mknod -m 660 $(ROOTFS)/dev/sda2 b 8 2
	-sudo mknod -m 660 $(ROOTFS)/dev/sda3 b 8 3
	-sudo mknod -m 660 $(ROOTFS)/dev/sda4 b 8 4
	-sudo mknod -m 600 $(ROOTFS)/dev/initctl p
	sudo chown `id -u`:`id -g` $(ROOTFS)/dev/*
	cd $(ROOTFS) && ln -sf sbin/init init
	install -m 755 $(CONFIG)/rcS $(ROOTFS)/etc/init.d/
	install -m 755 $(CONFIG)/rcS.actual $(ROOTFS)/etc/init.d/	
	install -m 755 $(CONFIG)/udhcp* $(ROOTFS)/etc/
	install -m 644 $(CONFIG)/passwd $(ROOTFS)/etc/
	install -m 644 $(CONFIG)/group $(ROOTFS)/etc/
	install -m 644 $(CONFIG)/services $(ROOTFS)/etc/
	install -m 644 $(CONFIG)/inittab $(ROOTFS)/etc/
	install -m 755 /usr/bin/lspci $(ROOTFS)/usr/bin/lspci
	# ubuntu or debian variation in location of example files:
	if [ -f /var/lib/misc/usb.ids ]; then \
    install -d $(ROOTFS)/var/lib/misc; \
   	install -m 755 /var/lib/misc/usb.ids $(ROOTFS)/var/lib/misc; \
	elif [ -f /var/lib/usbutils/usb.ids ]; then \
    install -d $(ROOTFS)/var/lib/usbutils; \
	 	install -m 755 /var/lib/usbutils/usb.ids $(ROOTFS)/var/lib/usbutils; \
  fi
	install -m 755 /sbin/shutdown $(ROOTFS)/sbin/
	echo "US/Eastern" > $(ROOTFS)/etc/timezone
	echo "pxe-$(VER)" > $(ROOTFS)/.omf_imageid

kernel: dirs get_kernel
	if [ ! -r $(BUILD)/$(KERNEL_NAME) ] ; then \
	  cp $(CONFIG)/$(KERNEL_CONFIG_FILE) $(SOURCE)/$(KERNEL_DIR)/.config ;\
	  $(MAKE) -C $(SOURCE)/$(KERNEL_DIR) -j$(KERNEL_BUILD_JOBS) bzImage; \
          cp $(SOURCE)/$(KERNEL_DIR)/arch/x86/boot/bzImage \
	    $(BUILD)/$(KERNEL_NAME) ; \
	fi
	# Note: current kernel expects init on initramfs on /init, not /sbin/init
initramfs: dirs bbox filesystem omf enroll syslinux kexec \
	getmac get_init_cpio
	rm -f $(BUILD)/$(INITRAMFS) $(BUILD)/$(INITRAMFSGZ)
	rm -rf $(ROOTFS)/usr/share/doc/ $(ROOTFS)/usr/share/man/
	/bin/bash $(SOURCE)/$(KERNEL_DIR)/scripts/gen_initramfs_list.sh \
		-u `id -u` -g `id -g` $(ROOTFS) > $(TEMP)/$(INITRAMFS_LIST)
	$(SOURCE)/$(KERNEL_DIR)/usr/gen_init_cpio \
		$(TEMP)/$(INITRAMFS_LIST) > $(BUILD)/$(INITRAMFS)
	bzip2 -f -9 $(BUILD)/$(INITRAMFS)

get_init_cpio: get_kernel
	if [ ! -f $(SOURCE)/$(KERNEL_DIR)/usr/gen_init_cpio ] ; then \
	  cd $(SOURCE)/$(KERNEL_DIR)/usr/ && make gen_init_cpio ;\
	fi

get_kernel:
	if [ ! -d $(SOURCE)/$(KERNEL_DIR) ] ; then \
	  wget -c -P $(SOURCE) $(KERNEL_TAR_URL); \
	  echo "Unpacking kernel sources..."; \
	  tar -xzf $(SOURCE)/$(KERNEL_TAR) -C $(SOURCE); \
	fi

get_bbox: 
	if [ ! -r $(SOURCE)/$(BBOX_TAR) ] ; then \
	wget -c -P $(SOURCE) $(BBOX_TAR_URL); \
	fi

install: kernel initramfs
	install -d $(DESTDIR)/$(TFTP_DIR)
	install -m666 $(BUILD)/$(KERNEL_NAME) $(DESTDIR)/$(TFTP_DIR)
	install -m666 $(BUILD)/$(INITRAMFSGZ) $(DESTDIR)/$(TFTP_DIR)
	install -m755 $(BUILD)/$(INITRAMFSGZ) $(DESTDIR)/$(TFTP_DIR)
	install -m755 $(BUILD)/$(PXE_DST) $(DESTDIR)/$(TFTP_DIR)
	install -d $(DESTDIR)/$(CFG_DIR)
	sed -e s/@KERNEL_VER@/$(KVER)/ $(CONFIG)/default.orbit | \
	  sed -e s/@VER@/$(VER)/ > $(DESTDIR)/$(CFG_DIR)/orbit-$(VER)
	install -m755 $(CONFIG)/makeLink $(DESTDIR)/$(CFG_DIR)

deb:
	debuild

apt-install: deb
	scp ../*.deb $(REPOSITORY):$(REPOSITORY_ROOT)/binary-i386
	scp ../*.gz $(REPOSITORY):$(REPOSITORY_ROOT)/source
	scp ../*.dsc $(REPOSITORY):$(REPOSITORY_ROOT)/source
	ssh $(REPOSITORY) sudo $(REPOSITORY_ROOT)/rebuild.sh

clean:
	rm -rf $(BUILD) $(ROOTFS)
	if [ -d $(SOURCE)/$(KERNEL_DIR) ] ; then \
	  $(MAKE) -C $(SOURCE)/$(KERNEL_DIR) clean ; \
	fi
	if [ -d $(SOURCE)/$(BBOX_DIR) ] ; then \
	  $(MAKE) -C $(SOURCE)/$(BBOX_DIR) clean ; \
	fi
	$(MAKE) -C $(GETMAC_DIR)/ clean

mrproper:
	rm -rf $(BUILD) $(ROOTFS) $(SOURCE) $(TEMP)

.PHONY: all apt-get-update dirs bbox omf syslinux getmac enroll \
	kexec filesystem kernel initramfs get_init_cpio get_kernelget_bbox \
	get_syslinux get_kexec install \
	deb apt-install clean mrproper
