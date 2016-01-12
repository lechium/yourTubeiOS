#import "OurViewController.h"

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
    NSLog(@"window: %@", _window);
    _viewController = [[OurViewController alloc] init];
    self.nav = [[UINavigationController alloc] initWithRootViewController:_viewController];
    [_viewController setDelegate:self];
    [_window setRootViewController:  self.nav];

  //  [_window setRootViewController:_viewController];
    //[_window addSubview:_viewController.view];
	[_window makeKeyAndVisible];
}

- (void)pushViewController:(id)controller
{
    [[self nav] pushViewController:controller animated:YES];
}

- (void)dealloc {
	
}
@end

// vim:ft=objc
