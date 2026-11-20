ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = rootless


PACKAGE_VERSION = 1.0b

INSTALL_TARGET_PROCESSES = backboardd aggregated
# INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += ReScale ReScaleUIKit ReScaleKB
SUBPROJECTS += ReScalePreferences
SUBPROJECTS += ReScaleActivator
include $(THEOS_MAKE_PATH)/aggregate.mk