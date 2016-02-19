//
//  yourTubeApplication.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import <AVFoundation/AVFoundation.h>
#import "KBYTDownloadsTableViewController.h"
#import "KBYTSearchTableViewController.h"
#import "KBYourTube.h"

@interface yourTubeApplication: UIApplication <UIApplicationDelegate> {
    UIWindow *_window;
    KBYTDownloadsTableViewController *_searchViewController;
}
@property (nonatomic, retain) UIWindow *window;
@property (strong, nonatomic) UINavigationController *nav;

@end
