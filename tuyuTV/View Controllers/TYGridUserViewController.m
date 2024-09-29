//
//  TYGridUserViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/15/16.
//
//https://stackoverflow.com/questions/33922186/how-to-enable-reordering-a-collection-view-in-tvos

#import "TYGridUserViewController.h"
#import "KBBulletinView.h"
#import "TYAuthUserManager.h"
#import "KBYTGridChannelViewController.h"
#import "UIView+RecursiveFind.h"

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

- (void)removeVideo:(KBYTSearchResult *)searchResult fromPlaylist:(KBYTPlaylist *)playlist inCollectionView:(UICollectionView *)cv {
    TLog(@"deleting %@ from %@ in %@", searchResult, playlist, cv);
    [[TYAuthUserManager sharedInstance] removeVideo:searchResult.videoId FromPlaylist:playlist.playlistID];
    [cv performBatchUpdates:^{
        NSMutableDictionary *_pldMutable = [self.playlistDictionary mutableCopy];
        NSMutableArray *playlistMutable = [playlist.videos mutableCopy];
        NSIndexPath *ip = [NSIndexPath indexPathForItem:[playlist.videos indexOfObject:searchResult] inSection:0];
        TLog(@"ip: %@", ip);
        [cv deleteItemsAtIndexPaths:@[ip]];
        [playlistMutable removeObject:searchResult];
        playlist.videos = playlistMutable;
        _pldMutable[playlist.title] = playlist;
        self.playlistDictionary = _pldMutable;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)removeChannel:(KBYTSearchResult *)searchResult inCollectionView:(UICollectionView *)cv {
    TLog(@"deleting %@ in %@", searchResult, cv);
    [[TYAuthUserManager sharedInstance] unSubscribeFromChannel:searchResult.stupidId];
    [cv performBatchUpdates:^{
        NSMutableDictionary *_pldMutable = [self.playlistDictionary mutableCopy];
        NSMutableArray *channelsMutable = [_pldMutable[@"Channels"] mutableCopy];
        NSIndexPath *ip = [NSIndexPath indexPathForItem:[channelsMutable indexOfObject:searchResult] inSection:0];
        TLog(@"ip: %@", ip);
        [cv deleteItemsAtIndexPaths:@[ip]];
        [channelsMutable removeObject:searchResult];
        _pldMutable[@"Channels"] = channelsMutable;
        self.playlistDictionary = _pldMutable;
    } completion:^(BOOL finished) {
        
    }];
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
            NSMutableDictionary *_pldMutable = [self.playlistDictionary mutableCopy];
            _pldMutable[playlist.title] = playlist;
            self.playlistDictionary = _pldMutable;
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
            TLog(@"This should never happen.");
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


- (void)goToChannelOfResult:(KBYTSearchResult *)searchResult {
    TLog(@"searchResult: %@", searchResult.channelId);
    if (!searchResult.channelId) {
        TLog(@"searchResult: %@", searchResult);
        return;
    }
    KBYTGridChannelViewController *cv = [[KBYTGridChannelViewController alloc] initWithChannelID:searchResult.channelId];
    [self presentViewController:cv animated:true completion:nil];
}


- (void)playPausePressed:(UITapGestureRecognizer *)gestureRecognizer {
    if (!_isBeingReordered)
        return;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    UICollectionView *view = (UICollectionView*)[[self focusedCollectionCell] superview];
    KBYTPlaylist *playlist = (KBYTPlaylist*)[self channelForCollectionView:view];
    KBYTSearchResult *result = [self searchResultFromFocusedCell];
    TLog(@"showing alert for result: %@", result);
    NSString *title = @"Are you sure you want to delete this video?";
    NSString *buttonTitle = @"Delete";
    if (result.resultType == kYTSearchResultTypeChannel){
        title = @"Are you sure you want to unsubscribe from this channel?";
        buttonTitle = @"Unsubscribe";
    }
    
    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:title message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        TLog(@"deleting item: %@", result);
        if (result.resultType == kYTSearchResultTypeChannel) {
            NSLog(@"unsub a channel?");
            [self stopReordering];
            [self removeChannel:result inCollectionView:view];
        } else if (result.resultType == kYTSearchResultTypeVideo) {
            NSLog(@"delete a video from a playlist?");
            [self stopReordering];
            [self removeVideo:result fromPlaylist:playlist inCollectionView:view];
        }
    }];
    [alertCon addAction:deleteAction];
    if (result.resultType == kYTSearchResultTypeChannel) {
        UIAlertAction *addToHome = [UIAlertAction actionWithTitle:@"Add to Home screen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[KBYourTube sharedInstance] addHomeSection:result];
        }];
        [alertCon addAction:addToHome];
        UIAlertAction *featured = [UIAlertAction actionWithTitle:@"Set as Featured channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[KBYourTube sharedInstance] setFeaturedResult:result];
        }];
        [alertCon addAction:featured];
    } else if (result.resultType == kYTSearchResultTypeVideo) {
        UIAlertAction *goToChannel = [UIAlertAction actionWithTitle:@"Go to Channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self goToChannelOfResult:result];
        }];
        [alertCon addAction:goToChannel];
    }
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
    
    if ([self loadCacheIfPossible]) {
        progress = false;
    }
    
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
        [self cacheDetails];
        [super reloadCollectionViews];
    }];
}

- (void)focusedCellStopJiggling {
    if ([self.focusedCollectionCell respondsToSelector:@selector(stopJiggling)]){
        [self.focusedCollectionCell performSelector:@selector(stopJiggling) withObject:nil afterDelay:0];
    }
}

- (void)focusedCellStartJiggling {
    if ([self.focusedCollectionCell respondsToSelector:@selector(startJiggling)]){
        [self.focusedCollectionCell performSelector:@selector(startJiggling) withObject:nil afterDelay:0];
    }
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

- (NSString *)userCacheFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"userGrid.plist"];
}

- (BOOL)cacheDetails {
    NSMutableDictionary *dict = [self.playlistDictionary convertObjectsToDictionaryRepresentations];
    dict[@"Featured"] = [self.featuredVideos convertArrayToDictionaries];
    //TLog(@"dict all keys: %@", dict.allKeys);
    return [dict writeToFile:[self userCacheFile] atomically:true];
}

- (BOOL)loadCacheIfPossible {
    if (![FM fileExistsAtPath:[self userCacheFile]]) {
        return FALSE;
    }
    NSDictionary *initial = [NSDictionary dictionaryWithContentsOfFile:[self userCacheFile]];
    self.playlistDictionary = [initial convertDictionaryToObjects];
    self.featuredVideos = self.playlistDictionary[@"Featured"];
    //TLog(@"set featured videos: %@", self.featuredVideos);
    if ([self isViewLoaded]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.featuredVideosCollectionView reloadData];
            [super reloadCollectionViews];
        });
    }
    return TRUE;
}

- (void)updateUserData:(NSDictionary *)userData {
    if (![self isViewLoaded]) {
        TLog(@"view isnt loaded yet, dont worry about syncing the data");
        return;
    }
    NSArray *channels = userData[@"channels"];
    NSArray *results = userData[@"results"];
    NSArray *currentChannels = self.playlistDictionary[@"Channels"];
    if (channels.count == currentChannels.count) {
        TLog(@"channel count remains unchanged");
    }
    NSMutableArray *allKeys = [self.playlistDictionary.allKeys mutableCopy];
    [allKeys removeObject:@"Channels"];
    [allKeys removeObject:@"Channel History"];
    [allKeys removeObject:@"Video History"];
    TLog(@"allKey count: %lu result count: %lu keys: %@", allKeys.count, results.count, allKeys);
    if (allKeys.count + 1 == results.count) {
        TLog(@"result count is unchanged, dont do sheeeat");
        return;
    }
    
    //TODO update whatever data requires it.
}

- (void)newCacheDetails {
    NSString *appSupport = [self appSupportFolder];
    NSArray *featured = [self.featuredVideos convertArrayToDictionaries];
    NSMutableDictionary *_newDict = [self.playlistDictionary mutableCopy];
    NSArray *channels = [self.playlistDictionary[@"Channels"] convertArrayToDictionaries];
    [_newDict removeObjectForKey:@"Channels"];
    [_newDict removeObjectForKey:@"Channel History"];
    [_newDict removeObjectForKey:@"Video History"];
    _newDict = [_newDict convertObjectsToDictionaryRepresentations];
    _newDict[@"Featured"] = featured;
    _newDict[@"Channels"] = channels;
    TLog(@"newDict keys: %@", [_newDict allKeys]);
    [_newDict writeToFile:[appSupport stringByAppendingPathComponent:@"user2.plist"] atomically:true];
}

- (void)fetchUserDetailsWithCompletion:(void(^)(NSArray *userDetails))completionBlock {
    NSMutableArray *finishedArray = [NSMutableArray new];
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    NSString *channelID = userDetails[@"channelID"];
    
    [[KBYourTube sharedInstance] getChannelVideos:channelID completionBlock:^(KBYTChannel *channel) {
        KBSection *section = [KBSection new];
        section.title = @"Channels";
        section.size = @"640x480";
        section.type = @"banner";
        section.autoScroll = false;
        section.infinite = false;
        section.sectionResultType = kYTSearchResultTypeChannelList; //there it is!
        section.content = channel.videos;
        section.channel = channel;
        [finishedArray addObject:section];
        
    } failureBlock:^(NSString *error) {
        DLog(@"error getting your channel videos: %@", error);
    }];
    
    NSArray <KBYTSearchResult *> *playlists = userDetails[@"results"];
    [playlists enumerateObjectsUsingBlock:^(KBYTSearchResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        KBSection *playlistSection = [obj sectionRepresentation];
        [finishedArray addObject:playlistSection];
    }];
    
    NSArray <KBCollectionItemProtocol> *channels = userDetails[@"channels"];
    if (channels.count > 0){
        KBSection *channelsSection = [KBSection new];
        channelsSection.title = @"Channels";
        channelsSection.size = @"320x240";
        channelsSection.type = @"standard";
        channelsSection.autoScroll = false;
        channelsSection.infinite = false;
        channelsSection.sectionResultType = kYTSearchResultTypeChannelList; //there it is!
        channelsSection.content = channels;
        [finishedArray addObject:channelsSection];
    }
    
    NSArray <KBCollectionItemProtocol> *channelHistoryItems = [[TYTVHistoryManager sharedInstance] channelHistoryObjects];
    if (channelHistoryItems.count > 0) {
        KBSection *channelHistory = [KBSection new];
        channelHistory.title = @"Channels";
        channelHistory.size = @"320x240";
        channelHistory.type = @"standard";
        channelHistory.autoScroll = false;
        channelHistory.infinite = false;
        channelHistory.sectionResultType = kYTSearchResultTypeChannelList; //there it is!
        channelHistory.content = channelHistoryItems;
        [finishedArray addObject:channelHistory];
    }
    
    NSArray <KBCollectionItemProtocol> *videoHistoryItems = [[TYTVHistoryManager sharedInstance] videoHistoryObjects];
    if (videoHistoryItems.count > 0) {
        KBSection *videoHistory = [KBSection new];
        videoHistory.title = @"Channels";
        videoHistory.size = @"320x240";
        videoHistory.type = @"standard";
        videoHistory.autoScroll = false;
        videoHistory.infinite = false;
        videoHistory.sectionResultType = kYTSearchResultTypeChannelList; //there it is!
        videoHistory.content = videoHistoryItems;
        [finishedArray addObject:videoHistory];
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
            //TLog(@"getting details for: %@ id: %@", result.title, result.videoId);
            [[KBYourTube sharedInstance] getPlaylistVideos:result.videoId completionBlock:^(KBYTPlaylist *searchDetails) {
                //TLog(@"got details for: %@", result.title);
                //TLog(@"details: %@", searchDetails);
                playlists[result.title] = searchDetails;
                //TLog(@"currentIndex: %lu count: %lu", currentIndex, playlistCount);
                currentIndex++;
                if (currentIndex == playlistCount) {
                    completionBlock(playlists);
                }
            } failureBlock:^(NSString *error) {
                //TLog(@"error: %@", error);
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
