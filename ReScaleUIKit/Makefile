ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReScaleUIKit

ReScaleUIKit_FILES = Tweak.xm
ReScaleUIKit_CFLAGS = -fobjc-arc -include Prefix.pch -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk