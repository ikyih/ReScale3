#include <substrate.h>
#include <dlfcn.h>
#include <objc/runtime.h>

#import <UIKit/UIKit.h>
#import <rootless.h>

@interface UIKeyboardImpl : UIView
+ (UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(NSInteger)arg1 inputMode:(id)arg2;
+ (CGSize)defaultSizeForInterfaceOrientation:(UIInterfaceOrientation)arg1;
+ (CGSize)keyboardSizeForInterfaceOrientation:(UIInterfaceOrientation)arg1;
+ (CGSize)sizeForInterfaceOrientation:(UIInterfaceOrientation)arg1;
@end

%hook UIKeyboardImpl
+ (CGSize)defaultSizeForInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	CGSize r = %orig;

	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return (CGSize){ CGRectInset(UIScreen.mainScreen.bounds, [self deviceSpecificPaddingForInterfaceOrientation:arg1 inputMode:nil].left, 0).size.width, r.height };
	}

	return r;
}

+ (CGSize)keyboardSizeForInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	CGSize r = %orig;

	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return (CGSize){ CGRectInset(UIScreen.mainScreen.bounds, [self deviceSpecificPaddingForInterfaceOrientation:arg1 inputMode:nil].left, 0).size.width, r.height };
	}

	return r;
}

+ (CGSize)sizeForInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	CGSize r = %orig;

	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return (CGSize){ CGRectInset(UIScreen.mainScreen.bounds, [self deviceSpecificPaddingForInterfaceOrientation:arg1 inputMode:nil].left, 0).size.width, r.height };
	}

	return r;
}
%end

%hook UIKeyboardLayoutStar
- (void)setFrame:(CGRect)arg1 {
	UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;

	if (UIInterfaceOrientationIsLandscape(orientation)) {
		%orig((CGRect){ CGPointZero, [UIKeyboardImpl keyboardSizeForInterfaceOrientation:orientation] });

		return;
	}

	%orig;
}
%end

%ctor {
	if (access(ROOT_PATH("/var/lib/dpkg/info/com.maiko.rescale3.list"), F_OK) == -1) return;

	if (objc_getClass("UIKeyboardImpl")) {
		%init();
	}
}