ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ReScalePreferences

ReScalePreferences_FILES = $(wildcard *.m) PFHeaderCell.mm
ReScalePreferences_FRAMEWORKS = UIKit WebKit
ReScalePreferences_INSTALL_PATH = /Library/PreferenceBundles
ReScalePreferences_CFLAGS = -fobjc-arc -include Prefix.pch -Wno-deprecated-declarations
ReScalePreferences_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk