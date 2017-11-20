//
//  AppDelegate.m
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

/*
 
 This is based on the swift sample at http://www.brianjcoleman.com/tvos-tutorial-video-app-in-swift/
 
 it made more sense to keep everything in obj-c since the rest of this project is in obj-c,
 took the code there and made a carbon copy into obj-cafied version, the most fun was re-adding 
 all the autolayout constraints, the plus side is im a bit more comfortable with autolayout now.
 
 for now this is just a POC to get some ATV4 work under my belt, need to actually adopt it to 
 use information and classes from the iOS version of tuyu in here. committing initial version from now 
 just to do it while its actually working :)
 
 
 */

#import "KBYTGridChannelViewController.h"
#import "AppDelegate.h"
#import "KBYourTube.h"
#import "KBYourTube+Categories.h"
#import "UserViewController.h"
#import "KBYTSearchTableViewController.h"
#import "KBYTSearchResultsViewController.h"
#import "SignOutViewController.h"
#import "WebViewController.h"
#import "AboutViewController.h"
#import "TYUserViewController.h"
#import "TYBaseGridViewController.h"
#import "TYGridUserViewController.h"
#import "TYHomeViewController.h"
#import "TYTVHistoryManager.h"
#import "TYSettingsViewController.h"
#import "YTTVPlaylistViewController.h"
#import "AFOAuthCredential.h"
#import "TYAuthUserManager.h"

@interface AppDelegate ()

@end





@implementation AppDelegate

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
   // DLOG_SELF;
    return UIBarPositionAny;
}

+ (NSUserDefaults *)sharedUserDefaults
{
    static dispatch_once_t pred;
    static NSUserDefaults* shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.tuyu"];
    });
    
    return shared;
}

- (UIViewController *)packagedSearchController
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    KBYTSearchResultsViewController *svc = [sb instantiateViewControllerWithIdentifier:@"SearchResultsViewController"];
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:svc];
    searchController.obscuresBackgroundDuringPresentation = true;
    searchController.hidesNavigationBarDuringPresentation = true;
    searchController.searchResultsUpdater = svc;
    searchController.searchBar.barStyle = UISearchBarStyleMinimal;
    searchController.searchBar.placeholder = @"YouTube search";
    searchController.edgesForExtendedLayout = UIRectEdgeNone;
    searchController.automaticallyAdjustsScrollViewInsets = false;
     searchController.extendedLayoutIncludesOpaqueBars = true;
    searchController.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    searchController.searchBar.delegate = self;
    CGRect searchBarFrame = CGRectMake(0, 60, 600, 60);
    searchController.searchBar.frame = searchBarFrame;
    UISearchContainerViewController *searchContainer = [[UISearchContainerViewController alloc] initWithSearchController:searchController];
    searchContainer.edgesForExtendedLayout = UIRectEdgeNone;
    searchContainer.automaticallyAdjustsScrollViewInsets = false;
    searchContainer.extendedLayoutIncludesOpaqueBars = true;
    searchContainer.title = @"search";
    
    searchContainer.view.backgroundColor = [UIColor blackColor];
    UINavigationController *searchNavigationController = [[UINavigationController alloc] initWithRootViewController:searchContainer];
    searchNavigationController.edgesForExtendedLayout = UIRectEdgeNone;

    return searchNavigationController;
}

- (TYGridUserViewController *)loggedInUserGridViewFromResults:(NSDictionary *)outputResults
{
    NSArray *results = outputResults[@"results"];
    NSMutableArray *_backingSectionLabels = [NSMutableArray new];
    
    for (KBYTSearchResult *result in results)
    {
        if (result.resultType == YTSearchResultTypePlaylist)
        {
            [_backingSectionLabels addObject:result.title];
        }
    }
    
    //bit of a kludge to support channels, if userDetails includes a channel key we add it at the very end
    
    if (outputResults[@"channels"] != nil)
    {
        [_backingSectionLabels addObject:@"Channels"];
    }
    
    NSArray *historyObjects = [[TYTVHistoryManager sharedInstance] channelHistoryObjects];
    
    if ([historyObjects count] > 0)
    {
        [_backingSectionLabels addObject:@"Channel History"];
        //  playlists[@"Channel History"] = historyObjects;
    }
    
    NSArray *videoHistory = [[TYTVHistoryManager sharedInstance] videoHistoryObjects];
    
    if ([videoHistory count] > 0)
    {
        [_backingSectionLabels addObject:@"Video History"];
        //  playlists[@"Channel History"] = historyObjects;
    }
    
    return [[TYGridUserViewController alloc] initWithSections:_backingSectionLabels];
}



- (void)updateForSignedIn
{
    NSMutableArray *viewControllers = [self.tabBar.viewControllers mutableCopy];
    if ([viewControllers count] == 5) { return; }
  //  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    [self.tabBar setSelectedIndex:0];
    [viewControllers removeObjectAtIndex:1];
    UIViewController *pvc = [self packagedSearchController];
    [viewControllers insertObject:pvc atIndex:1];
    if ([[KBYourTube sharedInstance] isSignedIn])
    {
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
            
            // NSLog(@"userdeets : %@", outputResults);
            [[KBYourTube sharedInstance] setUserDetails:outputResults];
            TYGridUserViewController *uvc = [self loggedInUserGridViewFromResults:outputResults];
            
            uvc.title = outputResults[@"userName"];
            if ([[outputResults allKeys]containsObject:@"altUserName"])
            {
                uvc.title = outputResults[@"altUserName"];
            }
            [viewControllers insertObject:uvc atIndex:1];
          /*
            [viewControllers removeLastObject];
            [viewControllers removeLastObject];
            SignOutViewController *svc = [SignOutViewController new];
            svc.title = @"sign out";
            [viewControllers addObject:svc];
            AboutViewController *avc = [AboutViewController new];
            avc.title = @"about";
            [viewControllers addObject:avc];
            TYSettingsViewController *settingsView = [TYSettingsViewController settingsView];
            [viewControllers addObject:settingsView];
           */
            self.tabBar.viewControllers = viewControllers;
            
            
        } failureBlock:^(NSString *error) {
            //
        }];
    }
}

- (void)updateForSignedOut
{
    NSMutableArray *viewControllers = [self.tabBar.viewControllers mutableCopy];
    [self.tabBar setSelectedIndex:0];
    if ([viewControllers count] == 5)
    {
        [viewControllers removeObjectAtIndex:1];
    }
   /*
    [viewControllers removeLastObject];
    [viewControllers removeLastObject];
    WebViewController *wvc = [[WebViewController alloc] init];
    wvc.title = @"sign in";
    [viewControllers addObject:wvc];
    AboutViewController *avc = [AboutViewController new];
    avc.title = @"about";
    [viewControllers addObject:avc];
    */
    self.tabBar.viewControllers = viewControllers;
    [[KBYourTube sharedInstance] setUserDetails:nil];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] clearAllCookies];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    DLog(@"url: %@ path: %@", url.host, url.path.lastPathComponent);
    
    YTSearchResultType type = [KBYourTube resultTypeForString:url.host];
    
    if (type == YTSearchResultTypeVideo)
    {
        [SVProgressHUD show];
        [[KBYourTube sharedInstance] getVideoDetailsForID:url.path.lastPathComponent completionBlock:^(KBYTMedia *videoDetails) {
            
            [SVProgressHUD dismiss];
            
            UIViewController *rvc = app.keyWindow.rootViewController;
            
            NSURL *playURL = [[videoDetails.streams firstObject] url];
            AVPlayerViewController *playerView = [[AVPlayerViewController alloc] init];
            AVPlayerItem *singleItem = [AVPlayerItem playerItemWithURL:playURL];
            
            playerView.player = [AVQueuePlayer playerWithPlayerItem:singleItem];
            [rvc presentViewController:playerView animated:YES completion:nil];
            [playerView.player play];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:singleItem];
            
            
        } failureBlock:^(NSString *error) {
            //
        }];
    } else if (type == YTSearchResultTypeChannel)
    {
        [self showChannel:url.path.lastPathComponent];
    } else if (type == YTSearchResultTypePlaylist)
    {
        
        NSString *path = url.path.lastPathComponent;
        NSArray *comp = [url.query componentsSeparatedByString:@"="];
        
        
        [self showPlaylist:path named:comp[1]];
    }
    
   
    
    return YES;
}

- (void)presentViewController:(UIViewController *)vc animated:(BOOL)isAnimated completion:(void (^ __nullable)(void))completion
{
    UIViewController *rvc = UIApplication.sharedApplication.keyWindow.rootViewController;
    [rvc presentViewController:vc animated:isAnimated completion:completion];
    
    
}

- (void)showPlaylist:(NSString *)videoID named:(NSString *)name
{
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getPlaylistVideos:videoID completionBlock:^(NSDictionary *searchDetails) {
        
        [SVProgressHUD dismiss];
        
        NSString *nextHREF = searchDetails[@"loadMoreREF"];
        YTTVPlaylistViewController *playlistViewController = [YTTVPlaylistViewController playlistViewControllerWithTitle:name backgroundColor:[UIColor blackColor] withPlaylistItems:searchDetails[@"results"]];
        playlistViewController.loadMoreHREF = nextHREF;
        [self presentViewController:playlistViewController animated:YES completion:nil];
        // [[self.presentingViewController navigationController] pushViewController:playlistViewController animated:true];
        
    } failureBlock:^(NSString *error) {
        //
    }];
}


- (void)showChannel:(NSString *)videoId
{
    
    KBYTGridChannelViewController *cv = [[KBYTGridChannelViewController alloc] initWithChannelID:videoId];
    [self presentViewController:cv animated:true completion:nil];
  /*
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    KBYTChannelViewController *cv = [sb instantiateViewControllerWithIdentifier:@"channelViewController"];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getChannelVideos:videoId completionBlock:^(NSDictionary *searchDetails) {
        
        [SVProgressHUD dismiss];
        
        [[TYTVHistoryManager sharedInstance] addChannelToHistory:searchDetails];
        cv.searchResults = searchDetails[@"results"];
        cv.pageCount = 1;
        cv.nextHREF = searchDetails[@"loadMoreREF"];
        cv.bannerURL = searchDetails[@"banner"];
        cv.channelTitle = searchDetails[@"name"];
        cv.subscribers = searchDetails[@"subscribers"];
        
        [self presentViewController:cv animated:true completion:nil];
        //[self.navigationController pushViewController:cv animated:true];
        
    } failureBlock:^(NSString *error) {
        
    }];
   */
}

- (void)itemDidFinishPlaying:(NSNotification *)n
{
    UIViewController *rvc = [[UIApplication sharedApplication]keyWindow].rootViewController;
    if ([rvc isKindOfClass:AVPlayerViewController.class])
    {
        [rvc dismissViewControllerAnimated:true completion:nil];

    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
   // [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:@"ChannelHistory"];
 
    
     NSLog(@"app support: %@", [self appSupportFolder]);
    self.tabBar = (UITabBarController *)self.window.rootViewController;
   // self.tabBar.tabBar.translucent = false;
    NSMutableArray *viewControllers = [self.tabBar.viewControllers mutableCopy];
    //UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NSArray *sectionArray = @[@"Popular on YouTube", @"Music", @"Sports", @"Gaming", @"360° Videos"];
    NSArray *idArray = @[KBYTPopularChannelID, KBYTMusicChannelID, KBYTSportsChannelID, KBYTGamingChannelID, KBYT360ChannelID];
    TYHomeViewController *hvc = [[TYHomeViewController alloc] initWithSections:sectionArray andChannelIDs:idArray];
   // hvc.channelIDs = idArray;
    hvc.title = @"tuyu";
    UIViewController *vc = [self packagedSearchController];
    [viewControllers removeObjectAtIndex:0];
    [viewControllers insertObject:hvc atIndex:0];
    [viewControllers insertObject:vc atIndex:1];
    TYSettingsViewController *settingsView = [TYSettingsViewController settingsView];
    [viewControllers addObject:settingsView];
    AboutViewController *avc = [AboutViewController new];
    avc.title = @"about";
    [viewControllers addObject:avc];
    self.tabBar.viewControllers = viewControllers;
    
    if ([[KBYourTube sharedInstance] isSignedIn])
    {
        DLog(@"%@", [TYAuthUserManager suastring]);
        [[TYAuthUserManager sharedInstance] checkAndSetCredential];
        
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
           
           //NSLog(@"userdeets : %@", outputResults);
            [[KBYourTube sharedInstance] setUserDetails:outputResults];
            
            TYGridUserViewController *uvc = [self loggedInUserGridViewFromResults:outputResults];
            
            uvc.title = outputResults[@"userName"];
            if ([[outputResults allKeys]containsObject:@"altUserName"])
            {
                uvc.title = outputResults[@"altUserName"];
            }
            [viewControllers insertObject:uvc atIndex:1];
            //[vc addObject:uvc];
            /*
            [viewControllers removeLastObject];
            [viewControllers removeLastObject];
            SignOutViewController *svc = [SignOutViewController new];
            svc.title = @"sign out";
            [viewControllers addObject:svc];
            AboutViewController *avc = [AboutViewController new];
            avc.title = @"about";
            TYSettingsViewController *settingsView = [TYSettingsViewController settingsView];
            [viewControllers addObject:settingsView];
            [viewControllers addObject:avc];
           */
            self.tabBar.viewControllers = viewControllers;
            
            
        } failureBlock:^(NSString *error) {
            //
        }];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MobileMode"]) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0 Mobile/12B410 Safari/601.2.7", @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MobileMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.7", @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MobileMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSData *cookieData = [[NSUserDefaults standardUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
  
  
    
    return YES;
}




- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[AppDelegate sharedUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[AppDelegate sharedUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[AppDelegate sharedUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[AppDelegate sharedUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSData *cookieData = [[AppDelegate sharedUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSData *cookieData = [[AppDelegate sharedUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[AppDelegate sharedUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[AppDelegate sharedUserDefaults] synchronize];
}

@end
