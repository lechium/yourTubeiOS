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
    
}

- (void)updateDownloadsProgress:(NSDictionary *)streamDictionary
{
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *dlplist = @"/var/mobile/Library/Application Support/tuyu/Downloads.plist";
    NSMutableArray *currentArray = nil;
    if ([man fileExistsAtPath:dlplist])
    {
        currentArray = [[NSMutableArray alloc] initWithContentsOfFile:dlplist];
        NSMutableDictionary *updateObject = [[currentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.outputFilename == %@", streamDictionary[@"file"]]]lastObject];
        NSInteger objectIndex = [currentArray indexOfObject:updateObject];
        if (objectIndex != NSNotFound)
        {
            [updateObject setValue:[NSNumber numberWithBool:false] forKey:@"inProgress"];
            
            [currentArray replaceObjectAtIndex:objectIndex withObject:updateObject];
        }
        
    } else {
        currentArray = [NSMutableArray new];
    }
    //[currentArray addObject:streamDictionary];
    [currentArray writeToFile:dlplist atomically:true];
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
            
            NSLog(@"we got a finisher");
          //  [self updateDownloadsProgress:userInfo];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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
