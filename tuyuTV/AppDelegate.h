//
//  AppDelegate.h
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIBarPositioningDelegate, UISearchBarDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) UITabBarController *tabBar;

- (void)updateForSignedIn;
- (void)updateForSignedOut;

@end

