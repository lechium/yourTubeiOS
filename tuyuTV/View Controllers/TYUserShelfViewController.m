//
//  TYUserShelfViewController.m
//  tuyuTV
//
//  Created by js on 9/28/24.
//

#import "TYUserShelfViewController.h"
#import "KBBulletinView.h"
#import "KBYourTube.h"
#import "TYAuthUserManager.h"

@interface TYUserShelfViewController () {
    NSInteger _highlightedCell;
    BOOL _didAdjustTotalHeight;
    BOOL _isBeingReordered;
    BOOL _canReOrder; //some items cant be re-ordered
    BOOL _userDataChanged;
}
@end

@implementation TYUserShelfViewController

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

- (void)collectionView:(UICollectionView*)cv moveCellFromRow:(NSInteger)artwork offset:(NSInteger)offset {
    KBSection *section = self.sections[cv.section];
    KBYTPlaylist *playlist = section.playlist;
    NSMutableArray *_data = [playlist.videos mutableCopy];
    TLog(@"moving from index: %lu to index: %lu", artwork, offset + artwork);
    if (artwork + offset >= 0 && artwork + offset <= [_data count] - 1) {
        [cv performBatchUpdates:^{
            [cv moveItemAtIndexPath:[NSIndexPath indexPathForItem:artwork inSection:0] toIndexPath:[NSIndexPath indexPathForItem:artwork + offset inSection:0]];
            [cv moveItemAtIndexPath:[NSIndexPath indexPathForItem:artwork + offset inSection:0] toIndexPath:[NSIndexPath indexPathForItem:artwork inSection:0]];
            _highlightedCell += offset;
            [_data exchangeObjectAtIndex:artwork withObjectAtIndex:artwork + offset];
            playlist.videos = _data;
            section.content = playlist.videos;
            //if there are certain elements in the cells that are position dependant, this is the right time to change them
            //because these cells are not reloaded by default (for example you have idx displayed in your cell... the cells will swap but idxs won't by default)
        } completion:^(BOOL finished) {
            [self focusedCellStartJiggling];
            //NSString *temp = _data[artwork + offset];
            //_data[artwork + offset] = _data[artwork];
            //_data[artwork] = temp;
        }];
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

- (UICollectionView *)collectionViewFromCell:(UICollectionViewCell *)cell {
    return [cell superview];
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];

    if ([context.nextFocusedView isKindOfClass:[UICollectionViewCell class]]) {
        if (_isBeingReordered) {
            TLog(@"This should never happen.");
        } else {
            UICollectionView *cv = [self collectionViewFromCell:(UICollectionViewCell *)context.nextFocusedView];
            NSInteger nextIdx = [cv indexPathForCell:(UICollectionViewCell *)context.nextFocusedView].row;

            if (nextIdx != _highlightedCell) {
                UICollectionViewCell *prevCell = (UICollectionViewCell*)[cv cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_highlightedCell inSection:0]];
                if ([prevCell isHighlighted])
                    prevCell.highlighted = false;
            }

            _highlightedCell = nextIdx;
        }
    }
}

- (void)handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {
    LOG_SELF;
    [super handleLongpressMethod:gestureRecognizer];
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if ([[KBYourTube sharedInstance] isSignedIn]) {
        if (self.focusedCollectionCell != nil) {
            UICollectionView *cv = (UICollectionView *)[self.focusedCollectionCell superview];
            if (cv.section == 0) return;
            if (_isBeingReordered == false) {
                KBSection *section = self.sections[cv.section];
                KBYTPlaylist *channel = section.playlist;
                NSIndexPath *ip = [cv indexPathForCell:self.focusedCollectionCell];
                KBYTSearchResult *result = section.content[ip.item];
                [self startReordering: (result.resultType == kYTSearchResultTypeVideo && [channel isKindOfClass:KBYTPlaylist.class])];
            } else {
                // [cv.visibleCells makeObjectsPerformSelector:@selector(stopJiggling)];
                [self stopReordering];
            }
        }
    }
}

- (void)handlePlaylistSection:(KBSection *)section completion:(void(^)(BOOL loaded, NSString *error))completionBlock {
    //DLog(@"section uniqueID: %@ title: %@", section.uniqueId, section.title);
    if (section.uniqueId) {
        [[TYAuthUserManager sharedInstance] getPlaylistItems:section.uniqueId completion:^(NSArray<KBYTSearchResult *> *playlistItems, NSString *error) {
            KBYTPlaylist *playlist = [KBYTPlaylist new];
            playlist.title = section.title;
            playlist.owner = section.subtitle;
            playlist.videos = playlistItems;
            playlist.playlistID = section.uniqueId;
            NSString *testOutput = [NSString stringWithFormat:@"%@_playlistSearchItems.plist", section.uniqueId];
            NSString *outputPath = [[self appSupportFolder] stringByAppendingPathComponent:testOutput];
            NSArray *writableArray = [playlistItems convertArrayToDictionaries];
            DLog(@"writing to file: %@", outputPath);
            [writableArray writeToFile:outputPath atomically:true];
            section.playlist = playlist;
            section.content = playlist.videos;
            if (completionBlock){
                completionBlock(true, nil);
            }
        }];
        /*[[KBYourTube sharedInstance] getPlaylistVideos:section.uniqueId completionBlock:^(KBYTPlaylist *playlist) {
            section.playlist = playlist;
            section.content = playlist.videos;
            //DLog(@"playlist videos: %@", playlist.videos);
            if (completionBlock){
                completionBlock(true, nil);
            }
        } failureBlock:^(NSString *error) {
            if (completionBlock){
                completionBlock(false, error);
            }
        }]; */
    } else {
        if (completionBlock){
            completionBlock(false, @"No Unique ID");
        }
    }
    
}

- (void)removeVideo:(KBYTSearchResult *)searchResult fromPlaylist:(KBYTPlaylist *)playlist inCollectionView:(UICollectionView *)cv {
    TLog(@"deleting %@ from %@ in %@", searchResult, playlist, cv);
    [[TYAuthUserManager sharedInstance] removeVideo:searchResult.stupidId ? searchResult.stupidId : searchResult.videoId FromPlaylist:playlist.playlistID];
    [cv performBatchUpdates:^{
        KBSection *section = self.sections[cv.section];
        NSMutableArray *playlistMutable = [playlist.videos mutableCopy];
        KBYTSearchResult *foundItem = [[playlist.videos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"stupidId == %@", searchResult.stupidId]] lastObject];
        DLog(@"foundItem: %@", foundItem);
        NSIndexPath *ip = [NSIndexPath indexPathForItem:[playlist.videos indexOfObject:foundItem] inSection:0];
        TLog(@"ip: %@", ip);
        [cv deleteItemsAtIndexPaths:@[ip]];
        [playlistMutable removeObject:foundItem];
        playlist.videos = playlistMutable;
        section.playlist = playlist;
        section.content = playlist.videos;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)removeChannel:(KBYTSearchResult *)searchResult inCollectionView:(UICollectionView *)cv {
    TLog(@"deleting %@ in %@", searchResult, cv);
    [[TYAuthUserManager sharedInstance] unSubscribeFromChannel:searchResult.stupidId];
    [cv performBatchUpdates:^{
        KBSection *section = self.sections[cv.section];
        KBYTChannel *channel = section.channel;
        NSMutableArray *channelsMutable = [[section content] mutableCopy];
        NSIndexPath *ip = [NSIndexPath indexPathForItem:[channelsMutable indexOfObject:searchResult] inSection:0];
        TLog(@"ip: %@", ip);
        [cv deleteItemsAtIndexPaths:@[ip]];
        [channelsMutable removeObject:searchResult];
        section.content = channelsMutable;
    } completion:^(BOOL finished) {
        
    }];
}


- (void)playPausePressed:(UITapGestureRecognizer *)gestureRecognizer {
    if (!_isBeingReordered)
        return;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    UICollectionView *view = (UICollectionView*)[[self focusedCollectionCell] superview];
    KBSection *section = self.sections[view.section];
    KBYTPlaylist *playlist = section.playlist;
    NSIndexPath *indexPath = [view indexPathForCell:self.focusedCollectionCell];
    KBYTSearchResult *result = section.content[indexPath.row];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    _pressGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressed:)];
        _pressGestureRecognizer.allowedPressTypes = @[@(UIPressTypeMenu), @(UIPressTypeSelect)];
        [self.view addGestureRecognizer:_pressGestureRecognizer];
    _pressGestureRecognizer.enabled = false;
    _playPauseGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed:)];
    _playPauseGestureRecognizer.allowedPressTypes = @[@(UIPressTypePlayPause)];
        [self.view addGestureRecognizer:_playPauseGestureRecognizer];
    _pressGestureRecognizer.enabled = false;
    _playPauseGestureRecognizer.enabled = false;
    // Do any additional setup after loading the view.
    _userDataChanged = false;
    [self listenForUserNotification];
}

- (void)listenForUserNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDataChanged:) name:KBYTUserDataChangedNotification object:nil];
}

- (void)userDataChanged:(NSNotification *)n {
    _userDataChanged = true;
    [[KBYourTube sharedInstance] fetchUserDetailsWithCompletion:^(NSArray<KBSectionProtocol> *userDetails, NSString *username) {
        self.sections = userDetails;
        dispatch_async(dispatch_get_main_queue(), ^{
            //if ([self topViewController] == self) {
               
                [self loadDataWithProgress:true loadingSnapshot:false completion:^(BOOL loaded) {
                    [self handleSectionsUpdated];
                }];
            _userDataChanged = false;
            //}
        });
    }];
}

- (NSString *)cacheFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"newUserShelf.plist"];
}

@end
