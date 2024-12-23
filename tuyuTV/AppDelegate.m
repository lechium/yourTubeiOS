//
//  AppDelegate.m
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//



#import "TYChannelShelfViewController.h"
#import "AppDelegate.h"
#import "KBYourTube.h"
#import "KBYourTube+Categories.h"
#import "KBYTSearchResultsViewController.h"
#import "AboutViewController.h"
#import "TYBaseGridViewController.h"
#import "TYTVHistoryManager.h"
#import "TYSettingsViewController.h"
#import "YTTVPlaylistViewController.h"
#import "YTTVPlayerViewController.h"
#import "AFOAuthCredential.h"
#import "TYAuthUserManager.h"
#import <unistd.h>
#import "tvOSShelfController.h"
#import "TYHomeShelfViewController.h"
#import "TYUserShelfViewController.h"

#define MODEL(n,p,i) [[KBModelItem alloc] initWithTitle:n imagePath:p uniqueID:i]
#define SMODEL(n,p,i) [[KBYTSearchResult alloc] initWithTitle:n imagePath:p uniqueID:i type:kYTSearchResultTypeVideo]


#define WELCOME_MSG  0
#define ECHO_MSG     2
#define WARNING_MSG  3

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

@interface AppDelegate ()
@property (nonatomic, strong) YTTVPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;
@end

@implementation AppDelegate

- (void)handleVideoMedia:(KBYTMedia *)media {
    UIApplication *app = UIApplication.sharedApplication;
    UIViewController *rvc = app.keyWindow.rootViewController;
    
    self.playerView = [[YTTVPlayerViewController alloc] initWithMedia:media];//[[YTTVPlayerViewController alloc] initWithFrame:rvc.view.frame usingStreamingMediaArray:@[searchResult]];
    [self presentViewController:self.playerView animated:YES completion:nil];
    [[self.playerView player] play];
}

- (TYHomeShelfViewController *)homeShelfViewController {
    NSMutableArray <KBSectionProtocol> *sections = [[[KBYourTube sharedInstance] homeScreenData] convertArrayToObjects];
    TYHomeShelfViewController *shelfViewController = [[TYHomeShelfViewController alloc] initWithSections:sections];
    shelfViewController.useRoundedEdges = false;
    shelfViewController.placeholderImage = [[UIImage imageNamed:@"YTPlaceholder.png"] roundedBorderImage:20.0 borderColor:nil borderWidth:0];
    //shelfViewController.sections = [self items];//[self loadData];
    shelfViewController.title = @"tuyu";
    
    return shelfViewController;
}



- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    // DLOG_SELF;
    return UIBarPositionAny;
}
/*
 + (NSUserDefaults *)sharedUserDefaults {
 static dispatch_once_t pred;
 static NSUserDefaults* shared = nil;
 
 dispatch_once(&pred, ^{
 shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.tuyu"];
 });
 
 return shared;
 }
 */
- (UIViewController *)packagedSearchController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    KBYTSearchResultsViewController *svc = [sb instantiateViewControllerWithIdentifier:@"SearchResultsViewController"];
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:svc];
    searchController.searchBar.scopeButtonTitles = @[@"All", @"Playlists", @"Channels"];
    searchController.searchBar.showsScopeBar = true;
    searchController.obscuresBackgroundDuringPresentation = true;
    searchController.hidesNavigationBarDuringPresentation = true;
    searchController.searchResultsUpdater = svc;
#if !TARGET_OS_TV
    searchController.searchBar.barStyle = UISearchBarStyleMinimal;
#endif
    searchController.searchBar.placeholder = @"YouTube search";
    searchController.edgesForExtendedLayout = UIRectEdgeNone;
    searchController.automaticallyAdjustsScrollViewInsets = false;
    searchController.extendedLayoutIncludesOpaqueBars = true;
    searchController.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    searchController.searchBar.delegate = svc;
    CGRect searchBarFrame = CGRectMake(0, 60, 600, 60);
    searchController.searchBar.frame = searchBarFrame;
    UISearchContainerViewController *searchContainer = [[UISearchContainerViewController alloc] initWithSearchController:searchController];
    searchContainer.edgesForExtendedLayout = UIRectEdgeNone;
    searchContainer.automaticallyAdjustsScrollViewInsets = false;
    searchContainer.extendedLayoutIncludesOpaqueBars = true;
    searchContainer.title = @"search";
    
    searchContainer.view.backgroundColor = [UIColor blackColor];/*
                                                                 UINavigationController *searchNavigationController = [[UINavigationController alloc] initWithRootViewController:searchContainer];
                                                                 searchNavigationController.edgesForExtendedLayout = UIRectEdgeNone;*/
    
    return searchContainer;
}

+ (NSString *)hostname {
    char baseHostName[256];
    int success = gethostname(baseHostName, 255);
    if (success != 0) return nil;
    baseHostName[255] = '\0';
    return [NSString stringWithFormat:@"%s", baseHostName];
}

- (void)startClient {
    
    netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    
    [netServiceBrowser setDelegate:self];
    [netServiceBrowser searchForServicesOfType:@"_tuyu._tcp." inDomain:@"local."];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender didNotSearch:(NSDictionary *)errorInfo {
    TLog(@"DidNotSearch: %@", errorInfo);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing {
    TLog(@"DidFindService: %@", [netService name]);
    
    if ([[netService name] isEqualToString:[AppDelegate hostname]]) {
        TLog(@"NO SOUP");
        return;
    }
    
    // Connect to the first service we find
    
    if (serverService == nil) {
        TLog(@"Resolving...");
        
        serverService = netService;
        
        [serverService setDelegate:self];
        [serverService resolveWithTimeout:5.0];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing {
    TLog(@"DidRemoveService: %@", [netService name]);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender {
    TLog(@"DidStopSearch");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    TLog(@"DidNotResolve");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    TLog(@"DidResolve: %@", [sender addresses]);
    
    if (serverAddresses == nil) {
        serverAddresses = [[sender addresses] mutableCopy];
    }
    
    if (asyncClientSocket == nil) {
        asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        //[self connectToNextAddress];
    }
}

- (void)connectToNextAddress {
    BOOL done = NO;
    while (!done && ([serverAddresses count] > 0)) {
        NSData *addr;
        
        // Note: The serverAddresses array probably contains both IPv4 and IPv6 addresses.
        //
        // If your server is also using GCDAsyncSocket then you don't have to worry about it,
        // as the socket automatically handles both protocols for you transparently.
        
        if (YES) // Iterate forwards
        {
            addr = [serverAddresses objectAtIndex:0];
            [serverAddresses removeObjectAtIndex:0];
        }
        else // Iterate backwards
        {
            addr = [serverAddresses lastObject];
            [serverAddresses removeLastObject];
        }
        
        TLog(@"Attempting connection to %@", addr);
        
        NSError *err = nil;
        if ([asyncSocket connectToAddress:addr error:&err]) {
            done = YES;
        }
        else
        {
            TLog(@"Unable to connect: %@", err);
        }
        
    }
    
    if (!done)
    {
        TLog(@"Unable to connect to any resolved address");
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    TLog(@"Socket:DidConnectToHost: %@ Port: %hu", host, port);
    
    [sock readDataWithTimeout:-1 tag:0];
    //[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
    
    connected = YES;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    TLog(@"SocketDidDisconnect:WithError: %@", err);
    if ([connectedSockets containsObject:sock]){
        [connectedSockets removeObject:sock];
    } else {
        if (!connected){
            [self connectToNextAddress];
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    TLog(@"didReadData: %@ tag: %lu", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], tag);
    if (tag == KBSocketOriginServer) {
        NSString *welcomeMsg = @"BRO!?\r\n";
        NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
        [sock writeData:welcomeData withTimeout:-1 tag:0];
        //[sock writeData:data withTimeout:-1 tag:ECHO_MSG];
        [sock readDataWithTimeout:-1 tag:KBSocketOriginClient];
    } else if (tag == KBSocketOriginClient) {
        
    }
}

- (void)startServer {
    // Create our socket.
    // We tell it to invoke our delegate methods on the main thread.
    
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // Create an array to hold accepted incoming connections.
    
    connectedSockets = [[NSMutableArray alloc] init];
    
    // Now we tell the socket to accept incoming connections.
    // We don't care what port it listens on, so we pass zero for the port number.
    // This allows the operating system to automatically assign us an available port.
    
    NSError *err = nil;
    if ([asyncSocket acceptOnPort:0 error:&err]) {
        // So what port did the OS give us?
        
        UInt16 port = [asyncSocket localPort];
        
        // Create and publish the bonjour service.
        // Obviously you will be using your own custom service type.
        
        netService = [[NSNetService alloc] initWithDomain:@"local."
                                                     type:@"_tuyu._tcp."
                                                     name:@""
                                                     port:port];
        
        [netService setDelegate:self];
        [netService publish];
        
        // You can optionally add TXT record stuff
        
        NSMutableDictionary *txtDict = [NSMutableDictionary dictionaryWithCapacity:2];
        
        [txtDict setObject:@"moo" forKey:@"cow"];
        [txtDict setObject:@"quack" forKey:@"duck"];
        
        NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
        [netService setTXTRecordData:txtData];
    } else {
        TLog(@"Error in acceptOnPort:error: -> %@", err);
    }
}


- (void)messageInABottle:(NSString *)value {
    //NSString *welcomeMsg = @"Welcome to the tuyu science Server\r\n";
    NSData *welcomeData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [connectedSockets enumerateObjectsUsingBlock:^(GCDAsyncSocket * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj writeData:welcomeData withTimeout:-1 tag:0];
    }];
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    // This method is executed on the socketQueue (not the main thread)
    
    if (tag == ECHO_MSG) {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
    }
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    TLog(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
    
    // The newSocket automatically inherits its delegate & delegateQueue from its parent.
    
    [connectedSockets addObject:newSocket];
    NSString *welcomeMsg = @"Welcome to the tuyu science Server\r\n";
    NSDictionary *dict = @{@"name": @"bro", @"test": @"science"};
    NSData *dictData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    //NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:dictData withTimeout:-1 tag:WELCOME_MSG];
    
    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}


- (void)netServiceDidPublish:(NSNetService *)ns {
    TLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
         [ns domain], [ns type], [ns name], (int)[ns port]);
    [self startClient];
}

- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict {
    // Override me to do something here...
    //
    // Note: This method in invoked on our bonjour thread.
    
    TLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
         [ns domain], [ns type], [ns name], errorDict);
}

- (void)updateForSignedIn {
    NSMutableArray *viewControllers = [self.tabBar.viewControllers mutableCopy];
    if ([viewControllers count] == 5) { return; }
    //  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    [self.tabBar setSelectedIndex:0];
    [viewControllers removeObjectAtIndex:1];
    UIViewController *pvc = [self packagedSearchController];
    [viewControllers insertObject:pvc atIndex:1];
    if ([[KBYourTube sharedInstance] isSignedIn]) {
        [[KBYourTube sharedInstance] fetchUserDetailsWithCompletion:^(NSArray<KBSectionProtocol> *userDetails, NSString *userName) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                TYUserShelfViewController *shelfViewController = [[TYUserShelfViewController alloc] initWithSections:userDetails];
                shelfViewController.useRoundedEdges = false;
                shelfViewController.placeholderImage = [[UIImage imageNamed:@"YTPlaceholder.png"] roundedBorderImage:20.0 borderColor:nil borderWidth:0];
                //shelfViewController.sections = [self items];//[self loadData];
                shelfViewController.title = userName;
                [viewControllers insertObject:shelfViewController atIndex:1];
                self.tabBar.viewControllers = viewControllers;
            });
        }];
      
    }
}

- (void)updateForSignedOut {
    NSMutableArray *viewControllers = [self.tabBar.viewControllers mutableCopy];
    [self.tabBar setSelectedIndex:0];
    if ([viewControllers count] == 5) {
        [viewControllers removeObjectAtIndex:1];
    }
    self.tabBar.viewControllers = viewControllers;
    [[KBYourTube sharedInstance] setUserDetails:nil];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] clearAllCookies];
}

void UncaughtExceptionHandler(NSException *exception) {
    @try {
        TLog(@"an exception occured: %@", exception);
        TLog(@"trace: %@", [NSThread callStackSymbols]);
    }
    @catch (NSException *exception) {
        TLog(@"caught exception: %@", exception);
    }
    @finally {
        @throw exception;
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    TLog(@"openURL url: %@ path: %@", url.host, url.path.lastPathComponent);
    
    YTSearchResultType type = [KBYourTube resultTypeForString:url.host];
    
    if (type == kYTSearchResultTypeVideo)
    {
        [SVProgressHUD show];
        [[KBYourTube sharedInstance] getVideoDetailsForID:url.path.lastPathComponent completionBlock:^(KBYTMedia *videoDetails) {
            
            [SVProgressHUD dismiss];
            [self handleVideoMedia:videoDetails];
            /*
            UIViewController *rvc = app.keyWindow.rootViewController;
            
            //NSURL *playURL = [[videoDetails.streams firstObject] url];
            NSURL *playURL = [NSURL URLWithString:[videoDetails hlsManifest]];
            AVPlayerViewController *playerView = [[AVPlayerViewController alloc] init];
            AVPlayerItem *singleItem = [AVPlayerItem playerItemWithURL:playURL];
            
            playerView.player = [AVQueuePlayer playerWithPlayerItem:singleItem];
            [rvc presentViewController:playerView animated:YES completion:nil];
            [playerView.player play];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:singleItem];
            
            */
        } failureBlock:^(NSString *error) {
            //
        }];
    } else if (type ==kYTSearchResultTypeChannel)
    {
        [self showChannel:url.path.lastPathComponent];
    } else if (type ==kYTSearchResultTypePlaylist)
    {
        
        NSString *path = url.path.lastPathComponent;
        NSArray *comp = [url.query componentsSeparatedByString:@"="];
        
        
        [self showPlaylist:path named:comp[1]];
    }
    
    
    
    return YES;
}

- (void)presentViewController:(UIViewController *)vc animated:(BOOL)isAnimated completion:(void (^ __nullable)(void))completion {
    UIViewController *rvc = UIApplication.sharedApplication.keyWindow.rootViewController;
    [rvc presentViewController:vc animated:isAnimated completion:completion];
    
    
}

- (void)pushViewController:(UIViewController *)vc animated:(BOOL)isAnimated completion:(void (^ __nullable)(void))completion {
    UIViewController *rvc = UIApplication.sharedApplication.keyWindow.rootViewController;
    if ([rvc navigationController]) {
        [[rvc navigationController] pushViewController:vc animated:true];
    } else {
        [self presentViewController:vc animated:isAnimated completion:completion];
    }
}


- (void)showPlaylist:(NSString *)videoID named:(NSString *)name {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getPlaylistVideos:videoID completionBlock:^(KBYTPlaylist *playlist) {
        
        [SVProgressHUD dismiss];
        
        //NSString *nextHREF = searchDetails[@"loadMoreREF"];
        YTTVPlaylistViewController *playlistViewController = [YTTVPlaylistViewController playlistViewControllerWithTitle:name backgroundColor:[UIColor blackColor] withPlaylistItems:playlist.videos];
        //playlistViewController.loadMoreHREF = nextHREF;
        [self pushViewController:playlistViewController animated:true completion:nil];
        //[self presentViewController:playlistViewController animated:YES completion:nil];
        // [[self.presentingViewController navigationController] pushViewController:playlistViewController animated:true];
        
    } failureBlock:^(NSString *error) {
        //
    }];
}


- (void)showChannel:(NSString *)videoId {
    TYChannelShelfViewController *cv = [[TYChannelShelfViewController alloc] initWithChannelID:videoId];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:cv animated:true completion:nil];
    });
    
}

- (void)itemDidFinishPlaying:(NSNotification *)n {
    UIViewController *rvc = [[UIApplication sharedApplication]keyWindow].rootViewController;
    if ([rvc isKindOfClass:AVPlayerViewController.class]) {
        [rvc dismissViewControllerAnimated:true completion:nil];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // [[KBYourTube sharedUserDefaults] setObject:@[] forKey:@"ChannelHistory"];
    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0 Mobile/12B410 Safari/601.2.7", @"UserAgent", nil];
    [[KBYourTube sharedUserDefaults] registerDefaults:dictionary];
    [[KBYourTube sharedUserDefaults] setBool:YES forKey:@"MobileMode"];
    [[KBYourTube sharedUserDefaults] synchronize];
    LOG_SELF;
    TLog(@"app support: %@", [self appSupportFolder]);
    self.tabBar = (UITabBarController *)self.window.rootViewController;
    // self.tabBar.tabBar.translucent = false;
    NSMutableArray *viewControllers = [NSMutableArray new];
    //UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    TYHomeShelfViewController *homeViewController = [self homeShelfViewController];
    UIViewController *searchViewController = [self packagedSearchController];
    //[viewControllers removeObjectAtIndex:0];
    [viewControllers insertObject:homeViewController atIndex:0];
    [viewControllers insertObject:searchViewController atIndex:1];
    [viewControllers addObject:[TYSettingsViewController settingsView]];
    AboutViewController *avc = [AboutViewController new];
    avc.title = @"about";
    [viewControllers addObject:avc];
    /*
    TYHomeShelfViewController *shelfNav = [self testShelfViewController];
    [viewControllers addObject:shelfNav];
     */
    self.tabBar.viewControllers = viewControllers;
    KBYourTube *kbyt = [KBYourTube sharedInstance];
    if ([kbyt isSignedIn]) {
        //DLog(@"%@", [TYAuthUserManager suastring]);
        [[TYAuthUserManager sharedInstance] checkAndSetCredential];
        [kbyt fetchUserDetailsWithCompletion:^(NSArray<KBSectionProtocol> *userDetails, NSString *userName) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                TYUserShelfViewController *shelfViewController = [[TYUserShelfViewController alloc] initWithSections:userDetails];
                shelfViewController.useRoundedEdges = false;
                shelfViewController.placeholderImage = [[UIImage imageNamed:@"YTPlaceholder.png"] roundedBorderImage:20.0 borderColor:nil borderWidth:0];
                //shelfViewController.sections = [self items];//[self loadData];
                shelfViewController.title = userName;
                [viewControllers insertObject:shelfViewController atIndex:1];
                self.tabBar.viewControllers = viewControllers;
            });
        }];
        
    }
    if ([[KBYourTube sharedUserDefaults] boolForKey:@"MobileMode"]) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0 Mobile/12B410 Safari/601.2.7", @"UserAgent", nil];
        [[KBYourTube sharedUserDefaults] registerDefaults:dictionary];
        [[KBYourTube sharedUserDefaults] setBool:YES forKey:@"MobileMode"];
        [[KBYourTube sharedUserDefaults] synchronize];
    }
    else {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.7", @"UserAgent", nil];
        [[KBYourTube sharedUserDefaults] registerDefaults:dictionary];
        [[KBYourTube sharedUserDefaults] setBool:NO forKey:@"MobileMode"];
        [[KBYourTube sharedUserDefaults] synchronize];
    }
    NSData *cookieData = [[KBYourTube sharedUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
    //[self startServer];
   
    
    return YES;
}




- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[KBYourTube sharedUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[KBYourTube sharedUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[KBYourTube sharedUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[KBYourTube sharedUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
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

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[KBYourTube sharedUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[KBYourTube sharedUserDefaults] synchronize];
}

@end
