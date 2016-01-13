#import "OurViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface yourTubeApplication: UIApplication <UIApplicationDelegate, OurViewControllerDelegate> {
	UIWindow *_window;
	OurViewController *_viewController;
}
@property (nonatomic, retain) UIWindow *window;
@property (strong, nonatomic) UINavigationController *nav;
@end

@implementation yourTubeApplication
@synthesize window = _window;
- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
     _viewController = [[OurViewController alloc] init];
    self.nav = [[UINavigationController alloc] initWithRootViewController:_viewController];
    [_viewController setDelegate:self];
    [_window setRootViewController:  self.nav];
	[_window makeKeyAndVisible];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error == nil) {
        [audioSession setActive:YES error:&error];
    }
    
}

- (void)pushViewController:(id)controller
{
    [[self nav] pushViewController:controller animated:YES];
}

- (void)dealloc {
	
}
@end

// vim:ft=objc
