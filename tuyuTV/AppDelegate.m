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

@interface AppDelegate ()

@end





@implementation AppDelegate



- (UIViewController *)packagedSearchController
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    KBYTSearchResultsViewController *svc = [sb instantiateViewControllerWithIdentifier:@"SearchResultsViewController"];
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:svc];
    searchController.searchResultsUpdater = svc;
    searchController.searchBar.placeholder = @"YouTube search";
    searchController.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    UISearchContainerViewController *searchContainer = [[UISearchContainerViewController alloc] initWithSearchController:searchController];
    searchContainer.title = @"search";
    searchContainer.view.backgroundColor = [UIColor blackColor];
    UINavigationController *searchNavigationController = [[UINavigationController alloc] initWithRootViewController:searchContainer];
    return searchNavigationController;
}

- (void)updateForSignedIn
{
    NSMutableArray *viewControllers = [self.tabBar.viewControllers mutableCopy];
    if ([viewControllers count] == 5) { return; }
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    [self.tabBar setSelectedIndex:0];
    [viewControllers removeObjectAtIndex:1];
    UIViewController *pvc = [self packagedSearchController];
    [viewControllers insertObject:pvc atIndex:1];
    if ([[KBYourTube sharedInstance] isSignedIn])
    {
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
            
            // NSLog(@"userdeets : %@", outputResults);
            [[KBYourTube sharedInstance] setUserDetails:outputResults];
            
          //  UserViewController *uvc = [sb instantiateViewControllerWithIdentifier:@"userViewController"];
            TYUserViewController *uvc = [[TYUserViewController alloc] init];
            //NSLog(@"uvc: %@", uvc);
            uvc.title = outputResults[@"userName"];
            [viewControllers insertObject:uvc atIndex:1];
            [viewControllers removeLastObject];
            [viewControllers removeLastObject];
            SignOutViewController *svc = [SignOutViewController new];
            svc.title = @"sign out";
            [viewControllers addObject:svc];
            AboutViewController *avc = [AboutViewController new];
            avc.title = @"about";
            [viewControllers addObject:avc];
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
    if ([viewControllers count] == 4)
    {
        [viewControllers removeObjectAtIndex:1];
    }
    
    [viewControllers removeLastObject];
    [viewControllers removeLastObject];
    WebViewController *wvc = [[WebViewController alloc] init];
    wvc.title = @"sign in";
    [viewControllers addObject:wvc];
    AboutViewController *avc = [AboutViewController new];
    avc.title = @"about";
    [viewControllers addObject:avc];
    self.tabBar.viewControllers = viewControllers;
    [[KBYourTube sharedInstance] setUserDetails:nil];
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.tabBar = (UITabBarController *)self.window.rootViewController;
    NSMutableArray *viewControllers = [self.tabBar.viewControllers mutableCopy];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [self packagedSearchController];
    [viewControllers insertObject:vc atIndex:1];
    AboutViewController *avc = [AboutViewController new];
    avc.title = @"about";
    [viewControllers addObject:avc];
    self.tabBar.viewControllers = viewControllers;
    
    if ([[KBYourTube sharedInstance] isSignedIn])
    {
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
           
           // NSLog(@"userdeets : %@", outputResults);
            [[KBYourTube sharedInstance] setUserDetails:outputResults];
            
           // UserViewController *uvc = [sb instantiateViewControllerWithIdentifier:@"userViewController"];
            TYUserViewController *uvc = [[TYUserViewController alloc] init];
            //NSLog(@"uvc: %@", uvc);
            uvc.title = outputResults[@"userName"];
            [viewControllers insertObject:uvc atIndex:1];
            //[vc addObject:uvc];
            [viewControllers removeLastObject];
            [viewControllers removeLastObject];
            SignOutViewController *svc = [SignOutViewController new];
            svc.title = @"sign out";
            [viewControllers addObject:svc];
            AboutViewController *avc = [AboutViewController new];
            avc.title = @"about";
            [viewControllers addObject:avc];
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
    [[NSUserDefaults standardUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    [[NSUserDefaults standardUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSData *cookieData = [[NSUserDefaults standardUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSData *cookieData = [[NSUserDefaults standardUserDefaults] objectForKey:@"ApplicationCookie"];
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
    [[NSUserDefaults standardUserDefaults] setObject:cookieData forKey:@"ApplicationCookie"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
