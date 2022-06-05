//
//  TYGridUserViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/15/16.
//
//https://stackoverflow.com/questions/33922186/how-to-enable-reordering-a-collection-view-in-tvos

#import "TYGridUserViewController.h"
#import "KBBulletinView.h"

@interface TYGridUserViewController () {
    NSInteger _highlightedCell;
    BOOL _didAdjustTotalHeight;
    BOOL _isBeingReordered;
    BOOL _canReOrder; //some items cant be re-ordered
}
@end

@implementation TYGridUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self refreshDataWithProgress:true];
    _pressGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressed:)];
        _pressGestureRecognizer.allowedPressTypes = @[@(UIPressTypeMenu), @(UIPressTypeSelect)];
        [self.view addGestureRecognizer:_pressGestureRecognizer];
    _pressGestureRecognizer.enabled = false;
    _playPauseGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed:)];
    _playPauseGestureRecognizer.allowedPressTypes = @[@(UIPressTypePlayPause)];
        [self.view addGestureRecognizer:_playPauseGestureRecognizer];
    _pressGestureRecognizer.enabled = false;
    _playPauseGestureRecognizer.enabled = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshDataWithProgress:false];
    _isBeingReordered = false;
    _canReOrder = false;
    menuTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleMenuTap:)];
    menuTapRecognizer.numberOfTapsRequired = 1;
    menuTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeMenu]];
    [self.view addGestureRecognizer:menuTapRecognizer];
    menuTapRecognizer.enabled = false;
}

- (void)collectionView:(UICollectionView*)cv moveCellFromRow:(NSInteger)artwork offset:(NSInteger)offset {
    KBYTPlaylist *playlist = (KBYTPlaylist*)[self channelForCollectionView:cv];
    NSMutableArray *_data = [playlist.videos mutableCopy];
    if (artwork + offset >= 0 && artwork + offset <= [_data count] - 1) {
        [cv performBatchUpdates:^{
            [cv moveItemAtIndexPath:[NSIndexPath indexPathForItem:artwork inSection:0] toIndexPath:[NSIndexPath indexPathForItem:artwork + offset inSection:0]];
            [cv moveItemAtIndexPath:[NSIndexPath indexPathForItem:artwork + offset inSection:0] toIndexPath:[NSIndexPath indexPathForItem:artwork inSection:0]];
            _highlightedCell += offset;
            [_data exchangeObjectAtIndex:artwork withObjectAtIndex:artwork + offset];
            playlist.videos = _data;
            NSMutableDictionary *_plMutable = [self.playlistDictionary mutableCopy];
            _plMutable[playlist.title] = playlist;
            self.playlistDictionary = _plMutable;
            //if there are certain elements in the cells that are position dependant, this is the right time to change them
            //because these cells are not reloaded by default (for example you have idx displayed in your cell... the cells will swap but idxs won't by default)
        } completion:^(BOOL finished) {
            [[self focusedCollectionCell] startJiggling];
            //NSString *temp = _data[artwork + offset];
            //_data[artwork + offset] = _data[artwork];
            //_data[artwork] = temp;
        }];
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];

    if ([context.nextFocusedView isKindOfClass:[YTTVStandardCollectionViewCell class]]) {
        if (_isBeingReordered) {
            NSLog(@"[tuyu] This should never happen.");
        } else {
            UICollectionView *cv = [self collectionViewFromCell:(UICollectionViewCell *)context.nextFocusedView];
            NSInteger nextIdx = [cv indexPathForCell:(UICollectionViewCell *)context.nextFocusedView].row;

            if (nextIdx != _highlightedCell) {
                YTTVStandardCollectionViewCell *prevCell = (YTTVStandardCollectionViewCell*)[cv cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_highlightedCell inSection:0]];
                if ([prevCell isHighlighted])
                    prevCell.highlighted = false;
            }

            _highlightedCell = nextIdx;
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context {
    if (_isBeingReordered) {
        if (!_canReOrder) {
            return false;
        }
        //code only supports horizontal reording.
        if (context.focusHeading == UIFocusHeadingRight) {
            [self collectionView:collectionView moveCellFromRow:_highlightedCell offset:1];
        }
        else if (context.focusHeading == UIFocusHeadingLeft) {
            [self collectionView:collectionView moveCellFromRow:_highlightedCell offset:-1];
        }
        return false;
    }
    return true;
}

- (void)playPausePressed:(UITapGestureRecognizer *)gestureRecognizer {
    if (!_isBeingReordered)
        return;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    KBYTSearchResult *result = [self searchResultFromFocusedCell];
    NSLog(@"[tuyu] showing alert for result: %@", result);
    NSString *title = @"Are you sure you want to delete this video?";
    NSString *buttonTitle = @"Delete";
    if (result.resultType == kYTSearchResultTypeChannel){
        title = @"Are you sure you want to unsubscribe from this channel?";
        buttonTitle = @"Unsubscribe";
    }
    
    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:title message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"[tuyu] deleting item: %@", result);
        if (result.resultType == kYTSearchResultTypeChannel) {
            NSLog(@"unsub a channel?");
        } else if (result.resultType == kYTSearchResultTypeVideo) {
            NSLog(@"delete a video from a playlist?");
        }
    }];
    [alertCon addAction:deleteAction];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertCon addAction:cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertCon animated:true completion:nil];
    });
}

- (void)pressed:(UITapGestureRecognizer *)gesture {
    if (!_isBeingReordered)
        return;
    [self stopReordering];
}

- (void)stopReordering {
    [self focusedCellStopJiggling];
    _isBeingReordered = false;
    _canReOrder = false;
    _pressGestureRecognizer.enabled = false;
    _playPauseGestureRecognizer.enabled = false;
    menuTapRecognizer.enabled = false;
}

- (void)startReordering:(BOOL)capable {
    [self focusedCellStartJiggling];
    [self showPlayPauseHint];
    _isBeingReordered = true;
    _canReOrder = capable;
    menuTapRecognizer.enabled = true;
    _pressGestureRecognizer.enabled = true;
    _playPauseGestureRecognizer.enabled = true;
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

- (void)focusedCellStopJiggling {
    [self.focusedCollectionCell performSelector:@selector(stopJiggling) withObject:nil afterDelay:0];
}

- (void)focusedCellStartJiggling {
    [self.focusedCollectionCell performSelector:@selector(startJiggling) withObject:nil afterDelay:0];
}

- (void)handleMenuTap:(id)sender {
    [self stopReordering];
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
        if (cv == self.featuredVideosCollectionView) return;
        if (_isBeingReordered == false) {
            //NSIndexPath *path = [cv indexPathForCell:self.focusedCollectionCell];
            //[cv beginInteractiveMovementForItemAtIndexPath:path];
            //   [cv.visibleCells  makeObjectsPerformSelector:@selector(startJiggling)];
            KBYTPlaylist *channel = (KBYTPlaylist*)[self channelForCollectionView:cv];
            KBYTSearchResult *result = [self searchResultFromFocusedCell];
            [self startReordering: (result.resultType == kYTSearchResultTypeVideo && [channel isKindOfClass:KBYTPlaylist.class])];
        } else {
            // [cv.visibleCells makeObjectsPerformSelector:@selector(stopJiggling)];
            [self stopReordering];
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
