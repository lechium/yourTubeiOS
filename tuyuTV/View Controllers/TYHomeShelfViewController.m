//
//  TYHomeShelfViewController.m
//  tuyuTV
//
//  Created by js on 9/22/24.
//

#import "TYHomeShelfViewController.h"
#import "SVProgressHUD.h"
#import "KBYourTube.h"
#import "TYChannelShelfViewController.h"
#import "TYTVHistoryManager.h"
#import "EXTScope.h"
#import "TYAuthUserManager.h"

@interface TYHomeShelfViewController () {
    BOOL _homeDataChanged;
    BOOL _tabBarSetup;
}

@end

@implementation TYHomeShelfViewController

//comment in to demo out tab bar stuff in home view

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_tabBarSetup) {
        [self setTabDetails:@[@"Videos", @"Playlists", @"Shorts"]];
        _tabBarSetup = true;
    }
}
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _homeDataChanged = false;
    [self listenForHomeNotification];
}

- (void)listenForHomeNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeDataChanged:) name:KBYTHomeDataChangedNotification object:nil];
}

- (void)homeDataChanged:(NSNotification *)n {
    _homeDataChanged = true;
    self.sections = [[[KBYourTube sharedInstance] homeScreenData] convertArrayToObjects];
    dispatch_async(dispatch_get_main_queue(), ^{
        //if ([self topViewController] == self) {
           
            [self loadDataWithProgress:true loadingSnapshot:false completion:^(BOOL loaded) {
                [self handleSectionsUpdated];
            }];
            _homeDataChanged = false;
        //}
    });
}

- (NSString *)cacheFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"newhome.plist"];
}

- (void)handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {
    [super handleLongpressMethod:gestureRecognizer];
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    [self handleLongPress:gestureRecognizer];
}

@end
