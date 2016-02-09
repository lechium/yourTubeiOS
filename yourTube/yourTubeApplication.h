//
//  yourTubeApplication.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import "OurViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "KBYTDownloadsTableViewController.h"
#import "KBYTSearchTableViewController.h"
#import "KBYourTube.h"

@interface yourTubeApplication: UIApplication <UIApplicationDelegate, OurViewControllerDelegate, KBYTSearchTableViewControllerDelegate> {
    UIWindow *_window;
    OurViewController *_viewController;
    KBYTDownloadsTableViewController *_searchViewController;
}
@property (nonatomic, retain) UIWindow *window;
@property (strong, nonatomic) UINavigationController *nav;

@end
