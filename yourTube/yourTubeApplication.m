

#import "yourTubeApplication.h"
#import "KBYourTube.h"
#import "TYAuthUserManager.h"
#import "NSFileManager+Size.h"

@implementation yourTubeApplication
@synthesize window = _window;

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[KBYTMessagingCenter sharedInstance] stopDownloadListener];
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[KBYourTube sharedUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[KBYourTube sharedUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[KBYourTube sharedUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[KBYourTube sharedUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[KBYTMessagingCenter sharedInstance] startDownloadListener];
    NSData *cookieData = [[KBYourTube sharedUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSData *cookieData = [[KBYourTube sharedUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    [KBYourTube sharedInstance]; //create it right off the bat to get device discovery going
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.backgroundColor = [UIColor whiteColor];
    _searchViewController = [[KBYTDownloadsTableViewController alloc] init];
    self.nav = [[UINavigationController alloc] initWithRootViewController:_searchViewController];
    [[UINavigationBar appearance] setTintColor:[UIColor redColor]];
    if (@available(iOS 15.0, *)) {
        //[UINavigationBar appearance].scrollEdgeAppearance = [[UINavigationBarAppearance alloc] init];
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        [navBarAppearance configureWithOpaqueBackground];
        //navBarAppearance.backgroundColor = [UIColor redColor];
        [UINavigationBar appearance].standardAppearance = navBarAppearance;
        [UINavigationBar appearance].scrollEdgeAppearance = navBarAppearance;
    }
    [_window setRootViewController:self.nav];
	[_window makeKeyAndVisible];
  
    NSData *cookieData = [[KBYourTube sharedUserDefaults] objectForKey:@"ApplicationCookie"];
   // DLog(@"cookieData: %@", cookieData);
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
    /*
    NSString *macUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/603.3.8 (KHTML, like Gecko) Version/10.1.2 Safari/603.3.8";
    
    NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:macUserAgent, @"UserAgent", nil];
    [[KBYourTube sharedUserDefaults] registerDefaults:dictionnary];
    */
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error == nil) {
        [audioSession setActive:YES error:&error];
    }
    NSLog(@"app support: %@", [self appSupportFolder]);
    NSArray *contents = [FM directoryContentsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Downloads"]];
    TLog(@"contents: %@", contents);
    NSLog(@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/603.3.8 (KHTML, like Gecko) Version/10.1.2 Safari/603.3.8");
   
    [[KBYTMessagingCenter sharedInstance] startDownloadListener];
    [[KBYTMessagingCenter sharedInstance] registerDownloadListener];
    //[[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    if ([[KBYourTube sharedInstance] isSignedIn] == true) {
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
            [[KBYourTube sharedInstance] setUserDetails:outputResults];
        } failureBlock:^(NSString *error) {
            NSLog(@"failed fetching user details with error: %@", error);
            [[TYAuthUserManager sharedInstance] signOut];
        }];
    } else {
        NSLog(@"is not signed in");
    }
    NSArray *fullArray = [NSArray arrayWithContentsOfFile:[self downloadFile]];
    TLog(@"fullArray %@", fullArray);
    NSArray *conts = [FM contentsOfDirectoryAtPath:[self absoluteDownloadFolder] error:nil];
    NSMutableArray *contsUpdated = [conts mutableCopy];
    NSMutableArray *fileArray = [NSMutableArray new];
    for (NSDictionary *itemDict in fullArray) {
        //KBYTLocalMedia *localMedia = [[KBYTLocalMedia alloc] initWithDictionary:itemDict];
        //[fileArray addObject:localMedia];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self == %@", itemDict[@"outputFilename"]];
        NSDictionary *found = [[conts filteredArrayUsingPredicate:pred] firstObject];
        if (found) {
            [fileArray addObject:found];
            [contsUpdated removeObject:found];
        }
    }
    /*
    TLog(@"adl: %@", [self absoluteDownloadFolder]);
    NSUInteger size = [NSFileManager sizeForFolderAtPath:[self absoluteDownloadFolder]];
    NSString *fancy = FANCY_BYTES(size);
    
    TLog(@"size: %@\ncontents: %@\ncontents unassociated: %@", fancy, conts, contsUpdated);
    [contsUpdated enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fullPath = [[self absoluteDownloadFolder] stringByAppendingPathComponent:obj];
        TLog(@"removing: %@", fullPath);
        //[FM removeItemAtPath:fullPath error:nil];
    }];
    size = [NSFileManager sizeForFolderAtPath:[self absoluteDownloadFolder]];
    fancy = FANCY_BYTES(size);
    TLog(@"updated size: %@", fancy);
     */
    /*
 
    NSDate *myStart = [NSDate date];
    
    [[KBYourTube sharedInstance] youTubeSearch:@"Drake rick ross" pageNumber:1 completionBlock:^(NSDictionary *searchDetails) {
        
        NSLog(@"time taken: %@ searchDetails: %@", [myStart timeStringFromCurrentDate], searchDetails);
        
    } failureBlock:^(NSString *error) {
        
        
    }];
    
  
    [[KBYourTube sharedInstance]getSearchResults:@"Drake rick ross" pageNumber:1 completionBlock:^(NSDictionary *searchDetails) {
      
        
        NSLog(@"time taken: %@ searchDetails: %@", [myStart timeStringFromCurrentDate], searchDetails);
        
        
    } failureBlock:^(NSString *error) {
        
        //
    }];
    
    */
}


- (void)pushViewController:(id)controller
{
    [[self nav] pushViewController:controller animated:YES];
}

- (void)dealloc {
	
}
@end

// vim:ft=objc
