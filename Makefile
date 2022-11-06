TARGET := iphone:clang:11.4:7.0
INSTALL_TARGET_PROCESSES = clipManager_daemon
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = qtierdaemon

qtierdaemon_FILES = Tweak.xm
qtierdaemon_FRAMEWORKS = UIKit
#qtierdaemon_PRIVATE_FRAMEWORKS = GraphicsServices
qtierdaemon_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
