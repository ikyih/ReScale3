#import "Tweak.h"

static NSString* ReScaleLocalizedString(NSString* key, NSString* value, NSString* table = @"Root") {
	static NSBundle* localizableBundle = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		localizableBundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/ReScalePreferences.bundle")];
	});

	return [localizableBundle localizedStringForKey:key value:value table:table];
}

static void ReScaleRefreshIdleTimer(void) {
	id monitor = [%c(SBIdleTimerGlobalStateMonitor) sharedInstance];
	if ([monitor respondsToSelector:@selector(_updateAutoDimDisabled)]) {
		[monitor _updateAutoDimDisabled];
		return;
	}

	id coordinator = [%c(SBIdleTimerGlobalCoordinator) sharedInstance];
	if ([coordinator respondsToSelector:@selector(_updateAutoDimDisableAssertion)]) {
		[coordinator _updateAutoDimDisableAssertion];
		return;
	}
	if ([coordinator respondsToSelector:@selector(_idleTimerPrefsChanged)]) {
		[coordinator _idleTimerPrefsChanged];
		return;
	}

	id backlight = [%c(SBBacklightController) sharedInstance];
	if ([backlight respondsToSelector:@selector(autoLockPrefsChanged)]) {
		[backlight autoLockPrefsChanged];
	}
}

static void ReScaleClearResolutionPrefs(void) {
	CFPreferencesSetAppValue(CFSTR("canvas_width"), NULL, CFSTR("tf.festival.rescale"));
	CFPreferencesSetAppValue(CFSTR("canvas_height"), NULL, CFSTR("tf.festival.rescale"));
	CFPreferencesSetAppValue(CFSTR("confirmedResolution"), NULL, CFSTR("tf.festival.rescale"));
	CFPreferencesSetAppValue(CFSTR("statusBarOverride"), NULL, CFSTR("tf.festival.rescale"));
	CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));
}

static void ReScaleKillGraphicsDaemons(void) {
	pid_t pid;
	int status;
	const char* args[] = {"killall", "-9", "backboardd", "aggregated", NULL};
	if (posix_spawn(&pid, ROOT_PATH("/usr/bin/killall"), NULL, NULL, (char* const*)args, NULL) == 0) {
		waitpid(pid, &status, 0);
	}
}

static Class ReScaleStatusBarProviderClass(void) {
	CFTypeRef value = CFPreferencesCopyAppValue(CFSTR("statusBarOverride"), CFSTR("tf.festival.rescale"));
	if (!value) return Nil;

	NSString* name = CFBridgingRelease(value);
	if (![name isKindOfClass:[NSString class]]) return Nil;

	Class provider = NSClassFromString(name);
	if (!provider) {
		NSLog(@"[ReScale2] no status bar provider for class %@", name);
	}

	return provider;
}

%group SpringBoard
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg1 {
	%orig;

	// Should not have used this in the first place. Sorry, @everyone!
	if ([idleTimerDefaults respondsToSelector:@selector(setDisableAutoDim:)]) {
		[idleTimerDefaults setDisableAutoDim:NO];
	}

	NSInteger canvasWidth = CFPreferencesGetAppIntegerValue(CFSTR("canvas_width"), CFSTR("tf.festival.rescale"), NULL);
	NSInteger canvasHeight = CFPreferencesGetAppIntegerValue(CFSTR("canvas_height"), CFSTR("tf.festival.rescale"), NULL);

	if ((canvasWidth && canvasHeight) && !CFPreferencesGetAppBooleanValue(CFSTR("confirmedResolution"), CFSTR("tf.festival.rescale"), NULL)) {
		__block NSTimer* countdownTimer;
		__block int countdownSecondsRemaining = 30;

		UIAlertController* resetDialog = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:ReScaleLocalizedString(@"RESOLUTION_APPLIED_TITLE", nil), canvasWidth, canvasHeight]
		                                                                     message:ReScaleLocalizedString(@"RESOLUTION_APPLIED_PROMPT", nil)
		                                                              preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:ReScaleLocalizedString(@"GENERIC_CONFIRM", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			CFPreferencesSetAppValue(CFSTR("confirmedResolution"), kCFBooleanTrue, CFSTR("tf.festival.rescale"));
			CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));

			ReScaleRefreshIdleTimer();

			if (countdownTimer) {
				[countdownTimer invalidate];
				countdownTimer = nil;
			}
		}];
		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:ReScaleLocalizedString(@"RESOLUTION_APPLIED_CANCEL", nil), countdownSecondsRemaining] style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
			if (countdownTimer) {
				[countdownTimer invalidate];
				countdownTimer = nil;
			}

			ReScaleClearResolutionPrefs();
			ReScaleRefreshIdleTimer();
			ReScaleKillGraphicsDaemons();
		}];

		[resetDialog addAction:confirmAction];
		[resetDialog addAction:cancelAction];

		UIWindow* targetWindow = nil;
		Class coverSheetWindowClass = %c(SBCoverSheetWindow);
		if (coverSheetWindowClass) {
			for (UIWindow* window in UIApplication.sharedApplication.windows) {
				if ([window isKindOfClass:coverSheetWindowClass]) {
					targetWindow = window;
					break;
				}
			}
		}
		if (!targetWindow) {
			targetWindow = UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.windows.firstObject;
		}

		[targetWindow.rootViewController presentViewController:resetDialog animated:YES completion:nil];

		countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer* timer) {
			[cancelAction setValue:[NSString stringWithFormat:ReScaleLocalizedString(@"RESOLUTION_APPLIED_CANCEL", nil), --countdownSecondsRemaining] forKeyPath:@"title"];

			if (countdownSecondsRemaining <= 0) {
				[timer invalidate];
				countdownTimer = nil;

				ReScaleClearResolutionPrefs();
				ReScaleKillGraphicsDaemons();

				return;
			}
		}];
	}
}
%end	/// %hook SpringBoard

%hook SBIdleTimerDefaults
- (id)init {
	idleTimerDefaults = %orig;
	return idleTimerDefaults;
}

- (BOOL)disableAutoDim {
	NSInteger canvasWidth = CFPreferencesGetAppIntegerValue(CFSTR("canvas_width"), CFSTR("tf.festival.rescale"), NULL);
	NSInteger canvasHeight = CFPreferencesGetAppIntegerValue(CFSTR("canvas_height"), CFSTR("tf.festival.rescale"), NULL);

	if ((canvasWidth && canvasHeight) && !CFPreferencesGetAppBooleanValue(CFSTR("confirmedResolution"), CFSTR("tf.festival.rescale"), NULL)) {
		return YES;
	}

	return %orig;
}
%end	/// %hook SBIdleTimerDefaults
%end	// %group SpringBoard

%group Applications
%hook _UIStatusBarVisualProvider_iOS
+ (Class)visualProviderSubclassForScreen:(id)arg1 {
	Class provider = ReScaleStatusBarProviderClass();
	if (provider) {
		return provider;
	}

	return %orig;
}

+ (Class)visualProviderSubclassForScreen:(id)arg1 visualProviderInfo:(id)arg2 {
	Class provider = ReScaleStatusBarProviderClass();
	if (provider) {
		return provider;
	}

	return %orig;
}
%end	/// %hook _UIStatusBarVisualProvider_iOS
%end	// %group Applications

%ctor {
	if (access(ROOT_PATH("/var/lib/dpkg/info/tf.festival.rescale2.list"), F_OK) == -1) return;

	if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
		%init(SpringBoard);
	}

	if (objc_getClass("_UIStatusBarVisualProvider_iOS")) {
		%init(Applications);
	}
}