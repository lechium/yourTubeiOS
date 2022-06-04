//
//  TYGridUserViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/15/16.
//
//

#import "TYGridUserViewController.h"
#import "KBBulletinView.h"

@interface TYGridUserViewController () {
    BOOL _didAdjustTotalHeight;
    BOOL _isBeingReordered;
}
@end

@implementation TYGridUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self refreshDataWithProgress:true];
    _pressGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressed:)];
        _pressGestureRecognizer.allowedPressTypes = @[@(UIPressTypeMenu), @(UIPressTypeSelect), @(UIPressTypePlayPause)];
        [self.view addGestureRecognizer:_pressGestureRecognizer];
    _pressGestureRecognizer.enabled = NO;
}

- (void)pressed:(UITapGestureRecognizer *)gesture {
    if (!_isBeingReordered)
        return;

    _isBeingReordered = NO;
    _pressGestureRecognizer.enabled = NO;
}


- (void)refreshDataWithProgress:(BOOL)progress {
    if (progress == true){
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
    }
    //get the user details to populate these views with
    [self fetchUserDetailsWithCompletionBlock:^(NSDictionary *finishedDetails) {
        
        if (progress == true){
            [SVProgressHUD dismiss];
        }
        self.playlistDictionary = finishedDetails;
        
        [super reloadCollectionViews];
    }];
}


- (void)swipeMethod:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (_jiggling) {
        //NSLog(@"[tuyu] direction: %lu", (unsigned long)gestureRecognizer.direction);
        CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
        //NSLog(@"[tuyu] location: %@", NSStringFromCGPoint(location));
        UICollectionView *cv = (UICollectionView *)[self.focusedCollectionCell superview];
        [cv updateInteractiveMovementTargetPosition:location];
    }
    
}

- (void)handleMenuTap:(id)sender {
    LOG_SELF;
    [self.focusedCollectionCell performSelector:@selector(stopJiggling) withObject:nil afterDelay:0];
    _jiggling = false;
    menuTapRecognizer.enabled = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshDataWithProgress:false];
    _jiggling = false;
    menuTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleMenuTap:)];
    menuTapRecognizer.numberOfTapsRequired = 1;
    menuTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeMenu]];
    [self.view addGestureRecognizer:menuTapRecognizer];
    menuTapRecognizer.enabled = false;
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    UIPressType type = presses.allObjects.firstObject.type;
    if ((_jiggling == true) && (type == UIPressTypeMenu)) {
        [self.focusedCollectionCell performSelector:@selector(stopJiggling) withObject:nil afterDelay:0];
        UICollectionView *cv = (UICollectionView *)[self.focusedCollectionCell superview];
        [cv endInteractiveMovement];
        _jiggling = false;
    } else {
        [super pressesBegan:presses withEvent:event];
    }
    
}

- (void)showPlayPauseHint {
    KBBulletinView *bulletin = [KBBulletinView playPauseOptionBulletin];
    [bulletin showFromController:self forTime:5];
}

- (void) handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if (self.focusedCollectionCell != nil) {
        UICollectionView *cv = (UICollectionView *)[self.focusedCollectionCell superview];
        if (_jiggling == false) {
            [self.focusedCollectionCell performSelector:@selector(startJiggling) withObject:nil afterDelay:0];
            NSIndexPath *path = [cv indexPathForCell:self.focusedCollectionCell];
            [cv beginInteractiveMovementForItemAtIndexPath:path];
            [self showPlayPauseHint];
            //   [cv.visibleCells  makeObjectsPerformSelector:@selector(startJiggling)];
            _jiggling = true;
            menuTapRecognizer.enabled = true;
        } else {
            
            [self.focusedCollectionCell performSelector:@selector(stopJiggling) withObject:nil afterDelay:0];
            // [cv.visibleCells makeObjectsPerformSelector:@selector(stopJiggling)];
            _jiggling = false;
            menuTapRecognizer.enabled = false;
        }
    }
    
}

- (void)fetchUserDetailsWithCompletionBlock:(void(^)(NSDictionary *finishedDetails))completionBlock {
    NSMutableDictionary *playlists = [NSMutableDictionary new];
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    // DLog(@"user details: %@", userDetails);
    NSString *channelID = userDetails[@"channelID"];
    NSInteger adjustment = 0; //a ghetto kludge to shoehorn channels in
    if (userDetails[@"channels"] != nil) {
        playlists[@"Channels"] = userDetails[@"channels"];
        adjustment = 0;
    }
    
    NSArray *historyObjects = [[TYTVHistoryManager sharedInstance] channelHistoryObjects];
    if ([historyObjects count] > 0) {
        if (![_backingSectionLabels containsObject:@"Channel History"]) {
            [_backingSectionLabels addObject:@"Channel History"];
        }
        playlists[@"Channel History"] = historyObjects;
        adjustment++;
    }
    NSArray *videoObjects = [[TYTVHistoryManager sharedInstance] videoHistoryObjects];
    if ([videoObjects count] > 0) {
        if (![_backingSectionLabels containsObject:@"Video History"]) {
            [_backingSectionLabels addObject:@"Video History"];
        }
        playlists[@"Video History"] = videoObjects;
        adjustment++;
    }
    
    [[KBYourTube sharedInstance] getChannelVideos:channelID completionBlock:^(KBYTChannel *searchDetails) {
        self.featuredChannel = searchDetails;
        self.featuredVideos = searchDetails.videos;
        [[self featuredVideosCollectionView] reloadData];
    } failureBlock:^(NSString *error) {
        //if (_didAdjustTotalHeight == false){
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.featuredVideosCollectionView.collectionViewLayout;
        [layout invalidateLayout];
        layout.itemSize = CGSizeMake(0, 0);
        //[self.featuredVideosCollectionView removeFromSuperview];
        //self.totalHeight -= 520;
        self.featuredHeightConstraint.constant = 0;
        [self.view setNeedsUpdateConstraints];
        [self.view layoutIfNeeded];
        //  _didAdjustTotalHeight = true;
    }];
    
    NSArray *results = userDetails[@"results"];
    __block NSInteger playlistCount = 0;
    
    /*
     
     the section labels will include "Channels" if we have channels, but we dont want to loop
     through there to get its "playlist" details because it doesnt have any. so if we
     changed adjustment to 1, we only cycle through the sections minus the last object
     
     */
    
    playlistCount = [_backingSectionLabels count]-adjustment;
    //since blocks are being used to fetch the data need to keep track of indices so we know
    //when to call completionBlock
    __block NSInteger currentIndex = 0;
    for (KBYTSearchResult *result in results) {
        if (result.resultType == kYTSearchResultTypePlaylist) {
            //NSLog(@"[tuyu] getting details for: %@ id: %@", result.title, result.videoId);
            [[KBYourTube sharedInstance] getPlaylistVideos:result.videoId completionBlock:^(KBYTPlaylist *searchDetails) {
                //NSLog(@"[tuyu] got details for: %@", result.title);
                //NSLog(@"[tuyu] details: %@", searchDetails);
                playlists[result.title] = searchDetails;
                //NSLog(@"[tuyu] currentIndex: %lu count: %lu", currentIndex, playlistCount);
                currentIndex++;
                if (currentIndex == playlistCount) {
                    completionBlock(playlists);
                }
            } failureBlock:^(NSString *error) {
                //NSLog(@"[tuyu] error: %@", error);
                playlistCount--;
                if (currentIndex == playlistCount) {
                    completionBlock(playlists);
                }
            }];
        } else {
            currentIndex++;
            if (currentIndex == playlistCount) {
                completionBlock(playlists);
            }
        }
    }
}

- (void)viewDidLayoutSubviews {
    [[self scrollView] setContentSize:CGSizeMake(1920, self.totalHeight)];
    // [self.view printRecursiveDescription];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
