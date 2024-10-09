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

@interface TYChannelShelfViewController () {
    KBYTChannelHeaderView *__headerView;
    KBYTChannel *__channel;
    BOOL _tabBarSetup;
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
        self.channel = channel;
        
        NSInteger tabIndex = [self.channel.tabs indexOfObject:tab];
        if (tabIndex > 0) {
            DLog(@"isnt the first tab: %lu", tabIndex);
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

/*
- (void)setupBlocks {
    [super setupBlocks];
    @weakify(self);
    self.itemFocusedBlock = ^(NSInteger row, NSInteger section, UICollectionView * _Nonnull collectionView) {
        //DLog(@"item focused: %lu in section: %lu", row,section);
        KBSection *currentSection = self_weak_.sections[section]; //TODO: crash proof with categories
        KBYTChannel *channel = currentSection.channel;
        //DLog(@"channel: %@", channel);
        if (currentSection.params) {
            DLog(@"channel section params: %@", currentSection.params);
            DLog(@"channel section browseId: %@", currentSection.browseId);
            if (row+1 == currentSection.content.count) {
                TLog(@"get a new page maybe?");
                [[KBYourTube sharedInstance] getChannelSection:channel section:currentSection params:currentSection.params continuation:nil completionBlock:^(KBYTChannel *channel) {
                    
                } failureBlock:^(NSString *error) {
                    
                }];
                [[KBYourTube sharedInstance] getChannelVideosAlt:currentSection.browseId params:currentSection.params continuation:nil completionBlock:^(KBYTChannel *channel) {
                    
                } failureBlock:^(NSString *error) {
                    
                }];
                //[self_weak_ getNextPage:channel inCollectionView:collectionView];
            }
        }
    };
}
*/
- (void)_performChannelUpdates {
    self.headerview.subscriberLabel.text = self.channel.subscribers;
    //self.headerview.subscriberLabel.text = channel.subscribers ? channel.subscribers : channel.subtitle;
    self.headerview.authorLabel.text = self.channel.title;
    self.sections = self.channel.sections;
    UIImage *banner = [UIImage imageNamed:@"Banner"];
    NSURL *imageURL =  [NSURL URLWithString:self.channel.banner];
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
    TLog(@"did select item at index: %lu current INdex: %lu", index, currentIndex);
    if (currentIndex == index) {
        TLog(@"dont!");
        return;
    }
    KBYTTab *tab = self.tabDetails[@(index)];
    TLog(@"found tab: %@ params: %@", tab.title, tab.params);
    [self fetchChannelDetails:tab];
}


- (void)viewDidLoad {
    [super viewDidLoad];
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
