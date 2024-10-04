//
//  TYHomeShelfViewController.m
//  tuyuTV
//
//  Created by js on 9/22/24.
//

#import "TYHomeShelfViewController.h"
#import "SVProgressHUD.h"
#import "KBYTGridChannelViewController.h"
#import "TYChannelShelfViewController.h"
#import "EXTScope.h"
#import "TYAuthUserManager.h"

@interface TYHomeShelfViewController () {
    BOOL _homeDataChanged;
}

@end

@implementation TYHomeShelfViewController

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


@end
