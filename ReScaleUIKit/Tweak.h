#include <dlfcn.h>
#include <spawn.h>
#include <unistd.h>
#include <sys/wait.h>
#include <substrate.h>

#import <UIKit/UIKit.h>
#import <rootless.h>

@class SBDashBoardIdleTimerController;

@interface SBBacklightController : NSObject
+ (id)sharedInstance;
- (void)autoLockPrefsChanged;				// iOS 9-10
@end

@interface SBIdleTimerDefaults : NSObject
- (void)setDisableAutoDim:(BOOL)arg1;
@end

@interface SBIdleTimerGlobalCoordinator : NSObject
+ (id)sharedInstance;
- (void)_idleTimerPrefsChanged;				// iOS 11
- (void)_updateAutoDimDisableAssertion;		// iOS 12
@end

@interface SBIdleTimerGlobalStateMonitor : NSObject
+ (id)sharedInstance;
- (void)_updateAutoDimDisabled;				// iOS 13-27
@end

@interface SpringBoard : UIApplication
@end

@interface UIAlertController (Private)
- (void)dismissAnimated:(BOOL)arg1;
- (void)_dismissAnimated:(BOOL)arg1 triggeringAction:(id)arg2;
@end



static SBIdleTimerDefaults* idleTimerDefaults;