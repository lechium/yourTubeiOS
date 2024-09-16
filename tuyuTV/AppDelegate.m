//
//  AppDelegate.m
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//


#import "KBYTGridChannelViewController.h"
#import "AppDelegate.h"
#import "KBYourTube.h"
#import "KBYourTube+Categories.h"
#import "KBYTSearchResultsViewController.h"
#import "WebViewController.h"
#import "AboutViewController.h"
#import "TYBaseGridViewController.h"
#import "TYGridUserViewController.h"
#import "TYHomeViewController.h"
#import "TYTVHistoryManager.h"
#import "TYSettingsViewController.h"
#import "YTTVPlaylistViewController.h"
#import "AFOAuthCredential.h"
#import "TYAuthUserManager.h"
#import <unistd.h>
#import "tvOSShelfController.h"

#define MODEL(n,p,i) [[KBModelItem alloc] initWithTitle:n imagePath:p uniqueID:i]
#define SMODEL(n,p,i) [[KBYTSearchResult alloc] initWithTitle:n imagePath:p uniqueID:i type:kYTSearchResultTypeVideo]


#define WELCOME_MSG  0
#define ECHO_MSG     2
#define WARNING_MSG  3

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

@interface AppDelegate ()

@end

@implementation AppDelegate

- (NSArray *)items {
    
    KBSection *section = [KBSection new];
    section.type = @"banner";
    section.size = @"1700x525";
    section.infinite = true;
    section.autoScroll = true;
    section.order = 0;
    section.className = @"KBYTSearchResult";
    
    KBYTSearchResult *modelItem = SMODEL(@"Drake - Worst Behavior", @"https://i.ytimg.com/vi/CccnAvfLPvE/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLBKduZRk6TRsKi8h4DE_cPajmtOcA", @"CccnAvfLPvE");
    section.content = @[modelItem];
    
    KBSection *sectionTwo = [KBSection new];
    sectionTwo.type = @"standard";
    sectionTwo.title = @"First";
    sectionTwo.size = @"320x240";
    sectionTwo.infinite = false;
    sectionTwo.autoScroll = false;
    sectionTwo.order = 1;
    sectionTwo.className = @"KBYTSearchResult";
    KBYTSearchResult *itemTwo = SMODEL(@"God's Plan", @"https://i.ytimg.com/vi/xpVfcZ0ZcFM/hqdefault.jpg", @"xpVfcZ0ZcFM");
    itemTwo.duration = @"5:32";
    sectionTwo.content = @[
        itemTwo,
        SMODEL(@"Rich Flex", @"https://i.ytimg.com/vi/I4DjHHVHWAE/hqdefault.jpg", @"I4DjHHVHWAE"),
        SMODEL(@"Spin Bout U", @"https://i.ytimg.com/vi/T8nbNQpRwNo/hqdefault.jpg", @"T8nbNQpRwNo"),
        SMODEL(@"MIA", @"https://i.ytimg.com/vi/NveQffpaOlU/hqdefault.jpg", @"NveQffpaOlU"),
        SMODEL(@"Search & Rescue", @"https://i.ytimg.com/vi/tVthyPOWc-E/hqdefault.jpg", @"tVthyPOWc-E"),
    ];
    
    KBSection *sectionThree = [KBSection new];
    sectionThree.type = @"standard";
    sectionThree.title = @"Second";
    sectionThree.size = @"640x480";
    sectionThree.infinite = false;
    sectionThree.autoScroll = false;
    sectionThree.order = 2;
    sectionThree.className = @"KBYTSearchResult";
    sectionThree.content = @[
        SMODEL(@"Drake - Worst Behavior", @"https://i.ytimg.com/vi/CccnAvfLPvE/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLBKduZRk6TRsKi8h4DE_cPajmtOcA", @"CccnAvfLPvE"),
        SMODEL(@"Drake - Stars (Official Music Video) 2023", @"https://i.ytimg.com/vi/R4DZBZJsoEY/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLAKZUsBLjiB8Ook77VQSqatPhaQ2g", @"R4DZBZJsoEY"),
        SMODEL(@"DJ Khaled ft. Drake - POPSTAR (Official Music Video - Starring Justin Bieber)", @"https://i.ytimg.com/vi/3CxtK7-XtE0/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLD9FC8VLEM86eZAY8awL1-3LgmM2g", @"3CxtK7-XtE0"),
        SMODEL(@"Meek Mill - Going Bad feat. Drake (Official Video)", @"https://i.ytimg.com/vi/S1gp0m4B5p8/hqdefault.jpg?sqp=-oaymwEjCOADEI4CSFryq4qpAxUIARUAAAAAGAElAADIQj0AgKJDeAE=&rs=AOn4CLD33ZfTKyCvv6OWsoN_imf2kx3vnQ", @"S1gp0m4B5p8"),
        SMODEL(@"Teenage Fever", @"https://i.ytimg.com/vi/e8HtwsnuTIw/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLDMtNcOuNNwmb7rVQfQYpmpOeWDbA", @"e8HtwsnuTIw"),
    ];
    
    KBSection *sectionFour = [KBSection new];
    sectionFour.type = @"standard";
    sectionFour.title = @"Third";
    sectionFour.size = @"320x240";
    sectionFour.infinite = false;
    sectionFour.autoScroll = false;
    sectionFour.order = 3;
    sectionFour.className = @"KBYTSearchResult";
    sectionFour.content = @[
        SMODEL(@"God's Plan", @"https://i.ytimg.com/vi/xpVfcZ0ZcFM/hqdefault.jpg", @"xpVfcZ0ZcFM"),
        SMODEL(@"Rich Flex", @"https://i.ytimg.com/vi/I4DjHHVHWAE/hqdefault.jpg", @"I4DjHHVHWAE"),
        SMODEL(@"Spin Bout U", @"https://i.ytimg.com/vi/T8nbNQpRwNo/hqdefault.jpg", @"T8nbNQpRwNo"),
        SMODEL(@"MIA", @"https://i.ytimg.com/vi/NveQffpaOlU/hqdefault.jpg", @"NveQffpaOlU"),
        SMODEL(@"Search & Rescue", @"https://i.ytimg.com/vi/tVthyPOWc-E/hqdefault.jpg", @"tVthyPOWc-E"),
    ];
    
    return @[section, sectionTwo, sectionThree, sectionFour];
}

- (KBShelfViewController *)createTempShelfViewController {
    KBShelfViewController *shelfViewController = [[KBShelfViewController alloc] init];
    shelfViewController.useRoundedEdges = false;
    shelfViewController.placeholderImage = [[UIImage imageNamed:@"YTPlaceholder.png"] roundedBorderImage:20.0 borderColor:nil borderWidth:0];
    shelfViewController.itemSelectedBlock = ^(KBModelItem * _Nonnull item, BOOL isLongPress) {
        DLog(@"item selected block: %@ long: %d", item, isLongPress);
    };
    shelfViewController.sections = [self items];//[self loadData];
    shelfViewController.title = @"tuyu Shelf";
    return shelfViewController;
    //UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:shelfViewController];
    //return nc;
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

- (TYGridUserViewController *)loggedInUserGridViewFromResults:(NSDictionary *)outputResults {
    NSArray *results = outputResults[@"results"];
    NSMutableArray *_backingSectionLabels = [NSMutableArray new];
    
    for (KBYTSearchResult *result in results) {
        if (result.resultType ==kYTSearchResultTypePlaylist) {
            [_backingSectionLabels addObject:result.title];
        }
    }
    
    //bit of a kludge to support channels, if userDetails includes a channel key we add it at the very end
    
    if (outputResults[@"channels"] != nil) {
        [_backingSectionLabels addObject:@"Channels"];
    }
    
    NSArray *historyObjects = [[TYTVHistoryManager sharedInstance] channelHistoryObjects];
    
    if ([historyObjects count] > 0) {
        [_backingSectionLabels addObject:@"Channel History"];
        //  playlists[@"Channel History"] = historyObjects;
    }
    
    NSArray *videoHistory = [[TYTVHistoryManager sharedInstance] videoHistoryObjects];
    
    if ([videoHistory count] > 0) {
        [_backingSectionLabels addObject:@"Video History"];
        //  playlists[@"Channel History"] = historyObjects;
    }
    
    return [[TYGridUserViewController alloc] initWithSections:_backingSectionLabels];
}



- (void)updateForSignedIn {
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
            
            self.tabBar.viewControllers = viewControllers;
            
            
        } failureBlock:^(NSString *error) {
            //
        }];
    }
}

- (void)updateForSignedOut {
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
    
    if (type ==kYTSearchResultTypeVideo)
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

- (void)showPlaylist:(NSString *)videoID named:(NSString *)name {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getPlaylistVideos:videoID completionBlock:^(KBYTPlaylist *playlist) {
        
        [SVProgressHUD dismiss];
        
        //NSString *nextHREF = searchDetails[@"loadMoreREF"];
        YTTVPlaylistViewController *playlistViewController = [YTTVPlaylistViewController playlistViewControllerWithTitle:name backgroundColor:[UIColor blackColor] withPlaylistItems:playlist.videos];
        //playlistViewController.loadMoreHREF = nextHREF;
        [self presentViewController:playlistViewController animated:YES completion:nil];
        // [[self.presentingViewController navigationController] pushViewController:playlistViewController animated:true];
        
    } failureBlock:^(NSString *error) {
        //
    }];
}


- (void)showChannel:(NSString *)videoId {
    KBYTGridChannelViewController *cv = [[KBYTGridChannelViewController alloc] initWithChannelID:videoId];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:cv animated:true completion:nil];
    });
    
}

- (void)itemDidFinishPlaying:(NSNotification *)n {
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
    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0 Mobile/12B410 Safari/601.2.7", @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MobileMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    LOG_SELF;
    TLog(@"app support: %@", [self appSupportFolder]);
    self.tabBar = (UITabBarController *)self.window.rootViewController;
    // self.tabBar.tabBar.translucent = false;
    NSMutableArray *viewControllers = [NSMutableArray new];
    //UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    TYHomeViewController *homeViewController = [[TYHomeViewController alloc] initWithData:[[KBYourTube sharedInstance] homeScreenData]];//[[TYHomeViewController alloc] initWithSections:sectionArray andChannelIDs:idArray];
    UIViewController *searchViewController = [self packagedSearchController];
    //[viewControllers removeObjectAtIndex:0];
    [viewControllers insertObject:homeViewController atIndex:0];
    [viewControllers insertObject:searchViewController atIndex:1];
    [viewControllers addObject:[TYSettingsViewController settingsView]];
    AboutViewController *avc = [AboutViewController new];
    avc.title = @"about";
    [viewControllers addObject:avc];
    KBShelfViewController *shelfNav = [self createTempShelfViewController];
    [viewControllers addObject:shelfNav];
    self.tabBar.viewControllers = viewControllers;
    KBYourTube *kbyt = [KBYourTube sharedInstance];
    if ([kbyt isSignedIn]) {
        //DLog(@"%@", [TYAuthUserManager suastring]);
        [[TYAuthUserManager sharedInstance] checkAndSetCredential];
        if ([kbyt loadUserDetailsFromCache]) {
            [kbyt setUserDetails:kbyt.userDetails];
            TYGridUserViewController *uvc = [self loggedInUserGridViewFromResults:kbyt.userDetails];
            uvc.title = kbyt.userDetails[@"userName"];
            if ([[kbyt.userDetails allKeys]containsObject:@"altUserName"]) {
                uvc.title = kbyt.userDetails[@"altUserName"];
            }
            [viewControllers insertObject:uvc atIndex:1];
            self.tabBar.viewControllers = viewControllers;
            
            //still want to fetch fresh after this..
            [kbyt getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
                [kbyt setUserDetails:outputResults];
                [uvc updateUserData:outputResults];
            } failureBlock:^(NSString *error) {
                
            }];
        } else {
            [kbyt getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
                
                //NSLog(@"userdeets : %@", outputResults);
                [kbyt setUserDetails:outputResults];
                TYGridUserViewController *uvc = [self loggedInUserGridViewFromResults:outputResults];
                uvc.title = outputResults[@"userName"];
                if ([[outputResults allKeys]containsObject:@"altUserName"]) {
                    uvc.title = outputResults[@"altUserName"];
                }
                [viewControllers insertObject:uvc atIndex:1];
                self.tabBar.viewControllers = viewControllers;
                
                
            } failureBlock:^(NSString *error) {
                //
            }];
        }
        
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
