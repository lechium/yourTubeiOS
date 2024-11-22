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

@interface TYChannelShelfViewController () {
    KBYTChannelHeaderView *__headerView;
    KBYTChannel *__channel;
    BOOL _tabBarSetup;
    UIView *aboutView;
    UILabel *aboutDescription;
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
    if (!imageURL) {
        [self.headerview.avatarImageView sd_setImageWithURL:[NSURL URLWithString:self.channel.avatar] placeholderImage:nil options:SDWebImageAvoidAutoSetImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            UIImage *roundedImage = [image roundedBorderImage:image.size.width/2 borderColor:nil borderWidth:0];
            self.headerview.avatarImageView.image = roundedImage;
        }]; /*
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
}


- (void)viewDidLoad {
    [super viewDidLoad];
    aboutView = [[UIView alloc] initForAutoLayout];
    aboutDescription = [[UILabel alloc] initForAutoLayout];
    [self.view addSubview:aboutView];
    [aboutView addSubview:aboutDescription];
    // Do any additional setup after loading the view.
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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
