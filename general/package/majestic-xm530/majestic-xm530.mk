################################################################################
#
# majestic-xm530
#
################################################################################

MAJESTIC_XM530_VERSION = current
MAJESTIC_XM530_SOURCE = majestic.xm530.master.tar.bz2
MAJESTIC_XM530_SITE = http://openipc.s3-eu-west-1.amazonaws.com
MAJESTIC_XM530_LICENSE = MIT
MAJESTIC_XM530_LICENSE_FILES = LICENSE

define MAJESTIC_XM530_INSTALL_TARGET_CMDS
	$(INSTALL) -m 755 -d $(TARGET_DIR)/etc
	$(INSTALL) -m 644 -t $(TARGET_DIR)/etc $(@D)/majestic.yaml

	$(INSTALL) -m 755 -d $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 755 -t $(TARGET_DIR)/usr/bin $(@D)/majestic
endef


$(eval $(generic-package))