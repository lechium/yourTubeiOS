#import "OurViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "KBYTDownloadsTableViewController.h"

@interface yourTubeApplication: UIApplication <UIApplicationDelegate, OurViewControllerDelegate> {
	UIWindow *_window;
	OurViewController *_viewController;
}
@property (nonatomic, retain) UIWindow *window;
@property (strong, nonatomic) UINavigationController *nav;
@end

@implementation yourTubeApplication
@synthesize window = _window;

- (void)applicationWillResignActive:(UIApplication *)application
{
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
    [center stopServer];
    //[super applicationWi]
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
    [center runServerOnCurrentThread];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    [KBYourTube sharedInstance]; //create it right off the bat to get device discovery going
    
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
    
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
    [center runServerOnCurrentThread];
    [center registerForMessageName:@"org.nito.dllistener.currentProgress" target:self selector:@selector(handleMessageName:userInfo:)];
    
    /*
    
    NSDate *myStart = [NSDate date];
    
    [[KBYourTube sharedInstance] youTubeSearch:@"Drake rick ross" pageNumber:1 completionBlock:^(NSDictionary *searchDetails) {
        
        NSLog(@"time taken: %@ searchDetails: %@", [myStart timeStringFromCurrentDate], searchDetails);
        
    } failureBlock:^(NSString *error) {
        
        
    }];
    
  
    [[KBYourTube sharedInstance]getSearchResults:@"Drake rick ross" completionBlock:^(NSDictionary *searchDetails) {
      
        
        NSLog(@"time taken: %@ searchDetails: %@", [myStart timeStringFromCurrentDate], searchDetails);
        
        
    } failureBlock:^(NSString *error) {
        
        //
    }];
    
    */
}

- (NSDictionary *)handleMessageName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    /*
     messageName: org.nito.dllistener.currentProgress userINfo: {
	    completionPercent = "0.1337406";
	    file = "Lil Wayne - Hollyweezy (Official Music Video) [720p].mp4";
     
     */
    
   // NSLog(@"messageName: %@ userINfo: %@", name, userInfo);
    if ([name.pathExtension isEqualToString:@"currentProgress"])
    {
        CGFloat progress = [userInfo[@"completionPercent"] floatValue];
        if (progress == 1.0)
        {
            NSString *file = userInfo[@"file"];
            if ([[file pathExtension] isEqualToString:@"aac"])
            {
                NSString *messageString = [NSString stringWithFormat:@"The file %@ has been successfully imported into your iTunes library under the album name tuyu downloads.", file];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Audio import complete" message:messageString delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
            }
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if ([[[self nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
            {
                [(KBYTDownloadsTableViewController*)[[self nav] visibleViewController] delayedReloadData];
            }
            
        } else {
            if ([[[self nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
            {
                [(KBYTDownloadsTableViewController*)[[self nav] visibleViewController] updateDownloadProgress:userInfo];
            }
            
        }
        
    }
    return nil;
}

- (void)pushViewController:(id)controller
{
    [[self nav] pushViewController:controller animated:YES];
}

- (void)dealloc {
	
}
@end

// vim:ft=objc
