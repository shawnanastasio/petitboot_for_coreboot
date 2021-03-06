################################################################################
#
# petitboot
#
################################################################################

PETITBOOT_VERSION = v1.7.6
PETITBOOT_SITE ?= $(call github,open-power,petitboot,$(PETITBOOT_VERSION))
PETITBOOT_DEPENDENCIES = ncurses udev host-bison host-flex lvm2 libgpgme
PETITBOOT_LICENSE = GPLv2
PETITBOOT_LICENSE_FILES = COPYING

PETITBOOT_AUTORECONF = YES
PETITBOOT_AUTORECONF_OPTS = -f -i
PETITBOOT_GETTEXTIZE = NO
PETITBOOT_CONF_OPTS += --with-ncurses --without-twin-x11 --without-twin-fbdev \
	      --localstatedir=/var --with-signed-boot \
	      HOST_PROG_KEXEC=/usr/sbin/kexec \
	      $(if $(BR2_PACKAGE_BUSYBOX),--with-tftp=busybox)

PETITBOOT_CONF_ENV += \
	ac_cv_path_GPGME_CONFIG=$(STAGING_DIR)/usr/bin/gpgme-config

ifdef PETITBOOT_DEBUG
	PETITBOOT_CONF_OPTS += --enable-debug
endif

ifeq ($(BR2_PACKAGE_PETITBOOT_MTD),y)
	PETITBOOT_CONF_OPTS += --enable-mtd
	PETITBOOT_DEPENDENCIES += libflash
	PETITBOOT_CPPFLAGS += -I$(STAGING_DIR)
	PETITBOOT_LDFLAGS += -L$(STAGING_DIR)
endif

ifeq ($(BR2_PACKAGE_NCURSES_WCHAR),y)
	PETITBOOT_CONF_OPTS += --with-ncursesw MENU_LIB=-lmenuw FORM_LIB=-lformw
endif

define PETITBOOT_PRECONFIGURE_FIXUP
	touch $(@D)/config.rpath
	test -d $(@D) || mkdir $(@D)/po
	touch $(@D)/po/Makefile.in.in
endef

PETITBOOT_PRE_CONFIGURE_HOOKS += PETITBOOT_PRECONFIGURE_FIXUP
PETITBOOT_PRE_CONFIGURE_HOOKS += PETITBOOT_PRE_CONFIGURE_BOOTSTRAP

define PETITBOOT_POST_INSTALL
	$(INSTALL) -D -m 0755 $(@D)/utils/bb-kexec-reboot \
		$(TARGET_DIR)/usr/libexec/petitboot
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/etc/petitboot/boot.d
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/01-create-default-dtb \
		$(TARGET_DIR)/etc/petitboot/boot.d/
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/90-sort-dtb \
		$(TARGET_DIR)/etc/petitboot/boot.d/

	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_PFC_PATH)/package/petitboot/S14silence-console \
		$(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_PFC_PATH)/package/petitboot/S15pb-discover \
		$(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_PFC_PATH)/package/petitboot/kexec-restart \
		$(TARGET_DIR)/usr/sbin/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_PFC_PATH)/package/petitboot/petitboot-console-ui.rules \
		$(TARGET_DIR)/etc/udev/rules.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_PFC_PATH)/package/petitboot/removable-event-poll.rules \
		$(TARGET_DIR)/etc/udev/rules.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_PFC_PATH)/package/petitboot/63-md-raid-arrays.rules \
		$(TARGET_DIR)/etc/udev/rules.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_PFC_PATH)/package/petitboot/65-md-incremental.rules \
		$(TARGET_DIR)/etc/udev/rules.d/

	ln -sf /usr/sbin/pb-udhcpc \
		$(TARGET_DIR)/usr/share/udhcpc/default.script.d/

	mkdir -p $(TARGET_DIR)/var/log/petitboot

endef

ifeq ($(BR2_PACKAGE_DTC),y)
	PETITBOOT_POST_INSTALL_TARGET_HOOKS +=
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/30-dtb_updates \
	$(TARGET_DIR)/etc/petitboot/boot.d/
endif


PETITBOOT_POST_INSTALL_TARGET_HOOKS += PETITBOOT_POST_INSTALL

$(eval $(autotools-package))
