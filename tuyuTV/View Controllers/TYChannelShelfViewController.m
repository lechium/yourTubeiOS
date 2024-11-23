//
//  TYChannelShelfViewController.m
//  tuyuTV
//
//  Created by js on 10/2/24.
//

#import "TYChannelShelfViewController.h"
#import "UIImageView+WebCache.h"
#import "KBYourTube.h"
#import "EXTScope.h"
#import "TYTVHistoryManager.h"
#import "KBTableViewCell.h"
#import "UIView+RecursiveFind.h"
#import "UIViewController+FocusHelper.h"
#import "TYAuthUserManager.h"

@interface TYChannelShelfViewController () {
    KBYTChannelHeaderView *__headerView;
    KBYTChannel *__channel;
    BOOL _tabBarSetup;
    UIView *aboutView;
    UILabel *aboutDescription;
    UIButton *subButton;
}
@end

@implementation TYChannelShelfViewController

- (KBYTChannel *)channel {
    return __channel;
}

- (KBYTTab *)selectedTab {
    if (self.tabBar) {
        UITabBarItem *selectedItem = self.tabBar.selectedItem;
        TLog(@"selectedItem: %@", selectedItem);
        NSInteger index = [self.tabBar.items indexOfObject:selectedItem];
        TLog(@"did select item at index: %lu", index);
        if (index != NSNotFound) {
            KBYTTab *tab = self.tabDetails[@(index)];
            return tab;
        }
    }
    return nil;
}

- (void)setChannel:(KBYTChannel *)channel {
    __channel = channel;
    [self channelUpdated];
}

- (BOOL)loadFromSnapshot {
    return FALSE; //dont do any snapshotting
}

- (void)snapshotResults { //dont do any snapshotting
    
}

- (void)fetchChannelDetails:(KBYTTab *)tab {
    [[KBYourTube sharedInstance] getChannelVideosAlt:self.channelID params:[tab params] continuation:nil completionBlock:^(KBYTChannel *channel) {
        if (channel.isAboutDetails) {
            self.channel.aboutDetails = channel.aboutDetails;
            aboutView.alpha = 1.0;
            aboutDescription.text = channel.aboutDetails;
        } else {
            aboutView.alpha = 0.0;
            self.channel = channel;
        }
        NSInteger tabIndex = [self.channel.tabs indexOfObject:tab];
        if (tabIndex > 0) {
            DLog(@"isnt the first tab: %lu title: %@", tabIndex, tab.title);
            dispatch_async(dispatch_get_main_queue(), ^{
                UICollectionViewCell *focusedCollectionCell = [self focusedCollectionCell];
                if (focusedCollectionCell) {
                    UICollectionView *cv = (UICollectionView *)[self.focusedCollectionCell superview];
                    //DLog(@"found collectionView: %@", cv);
                    //[cv setNeedsLayout];
                    //[cv layoutIfNeeded];
                    [cv reloadData];
                    [cv.collectionViewLayout invalidateLayout];
                } else {
                    NSInteger currentSection = self.selectedSection;
                    NSIndexPath *ip = [NSIndexPath indexPathForRow:currentSection inSection:0];
                    //DLog(@"indexPath: %@", ip);
                    KBTableViewCell *cell = (KBTableViewCell*)[self.tableView cellForRowAtIndexPath:ip];
                    //DLog(@"found cell: %@", cell);
                    UICollectionView *cv = [cell collectionView];
                    //DLog(@"cv: %@", cv);
                    //[cv setNeedsLayout];
                    //[cv layoutIfNeeded];
                    [cv reloadData];
                    [cv.collectionViewLayout invalidateLayout];
                }
                
            });
            
        }
        //[self.tableView reloadData];
    } failureBlock:^(NSString *error) {
        DLog(@"fetch channel failed with error: %@", error);
    }];
}


- (void)channelUpdated {
    if ([NSThread isMainThread]) {
        [self _performChannelUpdates];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _performChannelUpdates];
        });
    }
}

- (void)_performChannelUpdates {
    self.headerview.subscriberLabel.text = self.channel.subscribers;
    //self.headerview.subscriberLabel.text = channel.subscribers ? channel.subscribers : channel.subtitle;
    self.headerview.authorLabel.text = self.channel.title;
    self.sections = self.channel.sections;
    UIImage *banner = [UIImage imageNamed:@"Banner"];
    NSURL *imageURL =  [NSURL URLWithString:self.channel.banner];
    self.headerview.subToggledBlock = nil;
    self.headerview.subToggledBlock = ^{
        TLog(@"toggle sub value");
    };
    if (!imageURL) {
        if ([self.channelID isEqualToString:KBYTPopularChannelID]) {
            UIImage *trending = [UIImage imageNamed:@"trending"];
            //UIImage *trending = [UIImage imageNamed:@"trending_animated.webp"];
            TLog(@"trending: %@", trending);
            self.headerview.avatarImageView.image = [UIImage imageNamed:@"trending"];
        } else if ([self.channelID isEqualToString:KBYTSportsChannelID]){
            self.headerview.avatarImageView.image = [[UIImage imageNamed:@"sports"] roundedBorderImage:176/2 borderColor:nil borderWidth:0];
        } else if ([self.channelID isEqualToString:KBYTFashionAndBeautyID]){
            self.headerview.avatarImageView.image = [UIImage imageNamed:@"fashion"];
        } else if ([self.channelID isEqualToString:KBYTGamingChannelID]){
            self.headerview.avatarImageView.image = [UIImage imageNamed:@"gaming"];
        } else {
            [self.headerview.avatarImageView sd_setImageWithURL:[NSURL URLWithString:self.channel.avatar] placeholderImage:nil options:SDWebImageAvoidAutoSetImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                TLog(@"width: %f", image.size.width);
                UIImage *roundedImage = [image roundedBorderImage:image.size.width/2 borderColor:nil borderWidth:0];
                self.headerview.avatarImageView.image = roundedImage;
            }];
        }
        /*
         [self.headerview.avatarImageView sd_setImageWithURL:[NSURL URLWithString:self.channel.avatar] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
         [self.headerview updateRounding];
         }];*/
    }
    [self.headerview.bannerImageView sd_setImageWithURL:imageURL placeholderImage:banner options:SDWebImageAllowInvalidSSLCertificates];
    [[TYTVHistoryManager sharedInstance] addChannelToHistory:[self.channel dictionaryRepresentation]];
    if (self.channel.tabs.count > 1) {
        [self setTabDetails:self.channel.tabs];
    }
}

- (void)focusFailed:(NSNotification *)n {
    LOG_SELF;
    TLog(@"focus failed: %@", n);
    UIFocusUpdateContext *updateContext = (UIFocusUpdateContext*)[n userInfo][UIFocusUpdateContextKey];
    TLog(@"context: %@", updateContext);
    UIView *nextFocus = [updateContext nextFocusedItem];
    if ([updateContext focusHeading] == UIFocusHeadingUp) {
        TLog(@"were moving on up!");
        if (!nextFocus) {
            TLog(@"no next focus for you!");
            [self setViewToFocus:subButton];
        }
        
    }
    //[self showFocusDebugAlertController];
}

- (void)showFocusDealy:(id)sender {
    [self showFocusDebugAlertController];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    LOG_SELF;
    NSInteger currentIndex = [self selectedTabIndex];
    NSInteger index = [tabBar.items indexOfObject:item];
    TLog(@"did select item at index: %lu current Index: %lu", index, currentIndex);
    if (currentIndex == index) {
        TLog(@"dont!");
        return;
    }
    KBYTTab *tab = self.tabDetails[@(index)];
    TLog(@"found tab: %@ params: %@", tab.title, tab.params);
    [self fetchChannelDetails:tab];
}

- (void)afterSetupTabBar {
    LOG_SELF;
    [aboutView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = true;
    [aboutView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = true;
    [aboutView.topAnchor constraintEqualToAnchor:self.tabBar.bottomAnchor constant:50].active = true;
    //[aboutView.heightAnchor constraintEqualToConstant:300].active = true;
    [aboutView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = true;
    aboutView.alpha = 0.0;
    aboutView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    //[aboutDescription autoCenterInSuperview];
    [aboutDescription.topAnchor constraintEqualToAnchor:aboutView.topAnchor constant:100].active = true;
    [aboutDescription autoCenterVerticallyInSuperview];
    aboutDescription.text = @"test description";
    aboutDescription.numberOfLines = 0;
    aboutDescription.lineBreakMode = NSLineBreakByWordWrapping;
    [aboutDescription.widthAnchor constraintEqualToAnchor:aboutView.widthAnchor multiplier:0.75].active = true;
    aboutView.userInteractionEnabled = false;
    if ([[KBYourTube sharedInstance] isSignedIn]){
        BOOL isSubbed = [[TYAuthUserManager sharedInstance] isSubscribedToChannel:self.channelID];
        if (!subButton) {
            subButton = [UIButton buttonWithType:UIButtonTypeSystem];
            subButton.translatesAutoresizingMaskIntoConstraints = false;
            [self.view addSubview:subButton];
            //[subButton.centerYAnchor constraintEqualToAnchor:self.tabBar.centerYAnchor].active = true;
            [subButton setTitle:isSubbed ? @"UnSubscribe" : @"Subscribe" forState:UIControlStateNormal];
            [subButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40].active = true;
            [subButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:40].active = true;
            [subButton addTarget:self action:@selector(toggleSub:) forControlEvents:UIControlEventPrimaryActionTriggered];
            [self.view bringSubviewToFront:subButton];
        }
    }
}

- (void)toggleSub:(id)sender {
    LOG_SELF;
    BOOL isSubbed = [[TYAuthUserManager sharedInstance] isSubscribedToChannel:self.channelID];
    if (isSubbed) {
        NSString *stupidId = [[TYAuthUserManager sharedInstance] channelStupidIdForChannelID:self.channelID];
        TLog(@"found stupid id: %@", stupidId);
        if (stupidId){
            [[TYAuthUserManager sharedInstance] unSubscribeFromChannel:stupidId];
            [[KBYourTube sharedInstance] removeChannelIDFromUserDetails:self.channelID];
            [subButton setTitle:@"Subscribe" forState:UIControlStateNormal];
            //[[KBYourTube sharedInstance] removeChannelFromUserDetails:result];
        } else {
            TLog(@"failed to unsub! couldnt find stupid id for: %@", self.channelID);
            TLog(@"subbedChannels: %@", [[TYAuthUserManager sharedInstance] subbedChannelIDs])
            ;                    }
    } else {
        [[TYAuthUserManager sharedInstance] subscribeToChannel:self.channelID];
        [subButton setTitle:@"UnSubscribe" forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    aboutView = [[UIView alloc] initForAutoLayout];
    aboutDescription = [[UILabel alloc] initForAutoLayout];
    [self.view addSubview:aboutView];
    [aboutView addSubview:aboutDescription];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusFailed:) name:UIFocusMovementDidFailNotification object:nil];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIFocusMovementDidFailNotification object:nil];
}

/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 if (!_tabBarSetup) {
 [self setTabDetails:@[@"Videos", @"Playlists", @"Shorts"]];
 _tabBarSetup = true;
 }
 }
 */

- (KBYTChannelHeaderView *)headerview {
    if (__headerView != nil) return __headerView;
    
    __headerView = [[KBYTChannelHeaderView alloc] initForAutoLayout];
    return __headerView;
}

- (id)initWithChannelID:(NSString *)channelID {
    self = [super init];
    if (self) {
        self.channelID = channelID;
        [self fetchChannelDetails:nil];
    }
    return self;
}

- (id)initWithChannel:(KBYTChannel *)channel {
    self = [super init];
    if (self) {
        self.channel = channel;
        self.headerview.subscriberLabel.text = channel.subscribers;
        //self.headerview.subscriberLabel.text = channel.subscribers ? channel.subscribers : channel.subtitle;
        self.headerview.authorLabel.text = channel.title;
        self.sections = channel.sections;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIImage *banner = [UIImage imageNamed:@"Banner"];
    if (self.channel) {
        NSURL *imageURL =  [NSURL URLWithString:self.channel.banner];
        [self.headerview.bannerImageView sd_setImageWithURL:imageURL placeholderImage:banner options:SDWebImageAllowInvalidSSLCertificates];
    }
}

- (void)loadDataWithProgress:(BOOL)progress loadingSnapshot:(BOOL)loadingSnapshot completion:(void (^)(BOOL))completionBlock {
    if (completionBlock) {
        completionBlock(TRUE);
    }
}

/*
- (NSArray *) preferredFocusEnvironments {
    NSArray *sup = [super preferredFocusEnvironments];
    TLog(@"sup pref: %@", sup);
    return @[self.headerview.subButton];
    return sup;
}
 */
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
