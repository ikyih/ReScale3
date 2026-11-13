#include "substrate.h"
#import <UIKit/UIKit.h>
#import <rootless.h>

extern "C" CFIndex _CFPreferencesGetAppIntegerValueWithContainer(CFStringRef key, CFStringRef applicationID, id container, Boolean *keyExistsAndHasValidFormat);

static BOOL isCanvasKey(CFStringRef key, CFStringRef applicationID) {
	if (!key || !applicationID) return NO;
	if (CFStringCompare(applicationID, CFSTR("com.apple.iokit.IOMobileGraphicsFamily"), 0) != kCFCompareEqualTo) return NO;
	return CFStringCompare(key, CFSTR("canvas_width"), 0) == kCFCompareEqualTo
	    || CFStringCompare(key, CFSTR("canvas_height"), 0) == kCFCompareEqualTo;
}

%hookf(CFIndex, _CFPreferencesGetAppIntegerValueWithContainer, CFStringRef key, CFStringRef applicationID, id container, Boolean *keyExistsAndHasValidFormat) {
	if (isCanvasKey(key, applicationID)) {
		return CFPreferencesGetAppIntegerValue(key, CFSTR("tf.festival.rescale"), keyExistsAndHasValidFormat);
	}
	return %orig;
}

// Fallback in case iOS 16 reads the value through the public function instead
%hookf(CFIndex, CFPreferencesGetAppIntegerValue, CFStringRef key, CFStringRef applicationID, Boolean *keyExistsAndHasValidFormat) {
	if (isCanvasKey(key, applicationID)) {
		return %orig(key, CFSTR("tf.festival.rescale"), keyExistsAndHasValidFormat);
	}
	return %orig;
}

%ctor {
	if (access(ROOT_PATH("/var/lib/dpkg/info/com.maiko.rescale3.list"), F_OK) == -1) return;

	%init();
}