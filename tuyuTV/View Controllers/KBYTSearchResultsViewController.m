//
//  KBYTSearchResultsViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/7/16.
//
//

#import "KBYTSearchResultsViewController.h"
#import "YTTVStandardCollectionViewCell.h"
#import "SVProgressHUD.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "YTTVPlaylistViewController.h"
#import "TYTVHistoryManager.h"
#import "UIView+RecursiveFind.h"
#import "TYAuthUserManager.h"
#import "YTTVPlayerViewController.h"
#import "TYChannelShelfViewController.h"

@interface KBYTSearchResultsViewController () <UISearchBarDelegate>

@property (readwrite, assign) NSInteger currentPage;
@property (readwrite, assign) NSInteger rows; //5 items per row
@property (nonatomic, strong) NSString *filterString;
@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;
@property (nonatomic, strong) NSString *continuationToken;
@end

@implementation KBYTSearchResultsViewController

@synthesize pageCount, currentPage, filterString;

static NSString * const reuseIdentifier = @"NewStandardCell";

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    NSString *scope = searchBar.scopeButtonTitles[selectedScope];
    TLog(@"scope changed: %lu: %@", selectedScope, scope);
    [UD setValue:scope forKey:@"filterType"];
    _lastSearchResult = nil;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UILongPressGestureRecognizer *longpress
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongpressMethod:)];
    longpress.minimumPressDuration = .5; //seconds
    //longpress.delegate = self;
    longpress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect], [NSNumber numberWithInteger:UIPressTypePlayPause]];
    [self.collectionView addGestureRecognizer:longpress];
    
    // Do any additional setup after loading the view.
}

/*
- (UIView *)focusedView {
    UIFocusSystem *sys = [UIFocusSystem focusSystemForEnvironment: self];
    return [sys focusedItem];
}*/

-(void) handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {
    LOG_SELF;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    // DLog(@"at: %@", [UD valueForKey:@"access_token"]);
    if (![[KBYourTube sharedInstance] isSignedIn]) {
        return;
    }
    KBYTSearchResult *searchResult = [self searchResultFromFocusedCell];
    //TLog(@"searchResult: %@", searchResult);
    switch (searchResult.resultType) {
        case kYTSearchResultTypeVideo:
            
            [self showPlaylistAlertForSearchResult:searchResult];
            break;
            
        case kYTSearchResultTypeChannel:
            
            [self showChannelAlertForSearchResult:searchResult];
            break;
            
        case kYTSearchResultTypePlaylist:
            break;
            
        case kYTSearchResultTypeUnknown:
            break;
            
        case kYTSearchResultTypeChannelList:
            break;
    }
    
}

- (void)goToChannelOfResult:(KBYTSearchResult *)searchResult {
    TYChannelShelfViewController *cv = [[TYChannelShelfViewController alloc] initWithChannelID:searchResult.channelId];
    [self presentViewController:cv animated:true completion:nil];
}

- (void)promptForNewPlaylistForVideo:(KBYTSearchResult *)searchResult {
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"New Playlist"
                                          message: @"Enter the name for your new playlist"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        textField.placeholder = @"Playlist Name";
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.keyboardAppearance = UIKeyboardAppearanceDark;
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
    }];
    UIAlertAction *createPrivatePlaylist = [UIAlertAction
                                            actionWithTitle:@"Create private playlist"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action)
                                            {
        NSString *playlistName = alertController.textFields[0].text;
        KBYTSearchResult *playlistItem =  [[TYAuthUserManager sharedInstance] createPlaylistWithTitle:playlistName andPrivacyStatus:@"private"];
        NSLog(@"playlist created?: %@", playlistItem);
        
        /*
         
         etag = "\"m2yskBQFythfE4irbTIeOgYYfBU/vehTBMq9cEbTEevEChu3q4csUTk\"";
         id = PLnkIRfHufru8pR4pG2nDy2nQSHNxU3WFw;
         kind = "youtube#playlist";
         snippet =     {
         channelId = "UC-d63ZntP27p917VXU-VFiA";
         channelTitle = "Kevin Bradley";
         description = "";
         localized =         {
         description = "";
         title = "test 2";
         };
         publishedAt = "2017-08-15T16:19:38.000Z";
         thumbnails =         {
         default =             {
         height = 90;
         url = "http://s.ytimg.com/yts/img/no_thumbnail-vfl4t3-4R.jpg";
         width = 120;
         };
         high =             {
         height = 360;
         url = "http://s.ytimg.com/yts/img/no_thumbnail-vfl4t3-4R.jpg";
         width = 480;
         };
         medium =             {
         height = 180;
         url = "http://s.ytimg.com/yts/img/no_thumbnail-vfl4t3-4R.jpg";
         width = 320;
         };
         };
         title = "test 2";
         };
         status =     {
         privacyStatus = public;
         };
         
         */
        
        NSString *plID = playlistItem.videoId;
        
        [self addVideo:searchResult toPlaylist:plID];
    }];
    
    
    UIAlertAction *createPublicPlaylist = [UIAlertAction
                                           actionWithTitle:@"Create public playlist"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action)
                                           {
        NSString *playlistName = alertController.textFields[0].text;
        NSDictionary *playlistItem =  [[TYAuthUserManager sharedInstance] createPlaylistWithTitle:playlistName andPrivacyStatus:@"public"];
        if (playlistItem != nil)
        {
            NSLog(@"playlist created?: %@", playlistItem);
            NSString *plID = playlistItem[@"id"];
            
            [self addVideo:searchResult toPlaylist:plID];
        }
    }];
    
    
    [alertController addAction:createPrivatePlaylist];
    [alertController addAction:createPublicPlaylist];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)addVideo:(KBYTSearchResult *)video toPlaylist:(NSString *)playlist {
    DLog(@"add video: %@ to playlistID: %@", video, playlist);
    [[TYAuthUserManager sharedInstance] addVideo:video.videoId toPlaylistWithID:playlist];
}

- (void)showPlaylistAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Video Options"
                                          message: @"Choose playlist to add video to"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    NSArray *playlistArray = [[TYAuthUserManager sharedInstance] playlists];
    __weak typeof(self) weakSelf = self;
    self.alertHandler = ^(UIAlertAction *action) {
        NSString *playlistID = nil;
        for (KBYTSearchResult *result in playlistArray) {
            if ([result.title isEqualToString:action.title]) {
                playlistID = result.videoId;
            }
        }
        [weakSelf addVideo:result toPlaylist:playlistID];
    };
    
    for (KBYTSearchResult *result in playlistArray) {
        UIAlertAction *plAction = [UIAlertAction actionWithTitle:result.title style:UIAlertActionStyleDefault handler:self.alertHandler];
        [alertController addAction:plAction];
    }
    
    UIAlertAction *newPlAction = [UIAlertAction actionWithTitle:@"Create new playlist" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self promptForNewPlaylistForVideo:result];
    }];
    [alertController addAction:newPlAction];
    UIAlertAction *goToChannel = [UIAlertAction actionWithTitle:@"Go To Channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self goToChannelOfResult:result];
    }];
    [alertController addAction:goToChannel];
    if ([[KBYourTube sharedInstance] isSignedIn]) {
        UIAlertAction *subToChannel = [UIAlertAction actionWithTitle:@"Subscribe To Channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [[TYAuthUserManager sharedInstance] subscribeToChannel:result.channelId];
            });
        }];
        [alertController addAction:subToChannel];
    }
    
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showChannelAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Channel Options"
                                          message: @"Subscribe to this channel?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Subscribe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[TYAuthUserManager sharedInstance] subscribeToChannel:result.videoId];
        });
        
    }];
    [alertController addAction:yesAction];
    UIAlertAction *homeScreenAction = [UIAlertAction actionWithTitle:@"Add to Home screen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[KBYourTube sharedInstance] addHomeSection:result];
        });
        
    }];
    [alertController addAction:homeScreenAction];
    UIAlertAction *featuredAction = [UIAlertAction actionWithTitle:@"Set as Featured channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[KBYourTube sharedInstance] setFeaturedResult:result];
        });
        
    }];
    [alertController addAction:featuredAction];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
    }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    UISearchController *sc = [(UISearchContainerViewController*)self.presentingViewController searchController];
    [sc.searchBar becomeFirstResponder];
    
    //  [sc.view printRecursiveDescription];
    
    //  [[UIApplication sharedApplication] printWindow];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UISearchController *sc = [self searchController];
    sc.searchBar.frame = CGRectMake(0, 100, 600, 60);
    [self syncScopeBarWithDefaults];
}

- (UISearchController *)searchController {
    return [(UISearchContainerViewController*)self.presentingViewController searchController];
}

- (void)syncScopeBarWithDefaults {
    self.searchController.searchBar.selectedScopeButtonIndex = [self segmentIndexForDefault];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    UISearchController *sc = [self searchController];
    [sc.searchBar resignFirstResponder];
    //NSLog(@"sc: %@", sc);
    
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    //check to see if we are on the last row
    NSInteger rowCount = self.searchResults.count / 5;
    NSInteger currentRow = indexPath.row / 5;
    //TLog(@"indexRow : %lu currentRow: %lu rowCount: %lu, searchCount: %lu", indexPath.row, currentRow, rowCount, self.searchResults.count);
    if (currentRow+1 >= rowCount) {
        [self getNextPage];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YTTVStandardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    // Configure the cell
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    if (currentItem.resultType !=kYTSearchResultTypeVideo) {
        cell.overlayView.hidden = false;
        cell.overlayInfo.text = currentItem.details;
        cell.durationLabel.text = @"";
        cell.durationLabel.hidden = YES;
        
    } else {
        cell.overlayView.hidden = true;
        cell.overlayInfo.text = @"";
        cell.durationLabel.text = currentItem.duration;
        cell.durationLabel.hidden = NO;
    }
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
    [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            [cell.image sd_setImageWithURL:imageURL.highResVideoURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
        }
    }];
    if (currentItem.author.length > 0){
        cell.title.text = [NSString stringWithFormat:@"%@ - %@", currentItem.author, currentItem.title];
    } else {
        cell.title.text = currentItem.title;
    }
    
    return cell;
}

- (void)updateSearchResults:(KBYTSearchResults *)results {
    [SVProgressHUD dismiss];
    if (self.currentPage > 1) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:[[self searchResults] count]-1 inSection:0];
        [self.collectionView performBatchUpdates:^{
            NSMutableArray *allResults = [NSMutableArray new];
            [allResults addObjectsFromArray:results.videos];
            [allResults addObjectsFromArray:results.playlists];
            [allResults addObjectsFromArray:results.channels];
            [[self searchResults] addObjectsFromArray:allResults];
            NSMutableArray *indexPathArray = [NSMutableArray new];
            NSInteger i = 0;
            for (i = 0; i < [allResults count]; i++) {
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:lastIndexPath.item+i inSection:0];
                [indexPathArray addObject:newIndexPath];
            }
            
            [self.collectionView insertItemsAtIndexPaths:indexPathArray];
            
        } completion:^(BOOL finished) {
            
            //
        }];
        
    } else {
        NSMutableArray *allResults = [NSMutableArray new];
        [allResults addObjectsFromArray:results.videos];
        [allResults addObjectsFromArray:results.playlists];
        [allResults addObjectsFromArray:results.channels];
        self.searchResults = [allResults mutableCopy];
        [self.collectionView reloadData];
        
    }
}


- (void)itemDidFinishPlaying:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
    [[self.presentingViewController navigationController] popViewControllerAnimated:true];
}

- (NSInteger)segmentIndexForDefault {
    NSString *filterType = [UD valueForKey:@"filterType"];
    if (!filterType) return 0;
    if ([filterType isEqualToString:@"All"]) return 0;
    else if ([filterType isEqualToString:@"Playlists"]) return 1;
    else if ([filterType isEqualToString:@"Channels"]) return 2;
    return 0;
}

- (KBYTSearchType)searchTypeForSettings {
    NSString *filterType = [UD valueForKey:@"filterType"];
    if (!filterType){
        return KBYTSearchTypeAll;
    }
    if ([filterType isEqualToString:@"All"]) return KBYTSearchTypeAll;
    else if ([filterType isEqualToString:@"Playlists"]) return KBYTSearchTypePlaylists;
    else if ([filterType isEqualToString:@"Channels"]) return KBYTSearchTypeChannels;
    
    return KBYTSearchTypeAll;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.currentPage = 1; //reset for new search
    self.continuationToken = nil;
    if ([_lastSearchResult isEqualToString:searchController.searchBar.text] || searchController.searchBar.text.length == 0) {
        //no need to refresh a search with an old string...
        return;
    }
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[self searchResults] removeAllObjects];
    self.filterString = searchController.searchBar.text;
    _lastSearchResult = self.filterString;
    
    KBYTSearchType type = [self searchTypeForSettings];
    //TLog(@"search type: %lu", type);
    [[KBYourTube sharedInstance] apiSearch:self.filterString type:type continuation:self.continuationToken completionBlock:^(KBYTSearchResults *result) {
        //TLog(@"search results: %@", result.videos);
        self.continuationToken = result.continuationToken;
        self.pageCount = 20; //just choosing an arbitrary number
        [self updateSearchResults:result];
    } failureBlock:^(NSString *error) {
        
    }];
}

- (KBYTSearchResult *)searchResultFromFocusedCell {
    if (self.focusedCollectionCell != nil) {
        UICollectionView *cv = self.collectionView;
        NSIndexPath *indexPath = [cv indexPathForCell:self.focusedCollectionCell];
        KBYTSearchResult *searchResult = [self.searchResults objectAtIndex:indexPath.row];
        return searchResult;
    }
    return nil;
}


- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    
    self.focusedCollectionCell = (UICollectionViewCell *)context.nextFocusedView;
    //YTTVStandardCollectionViewCell *selectedCell = (YTTVStandardCollectionViewCell*)context.nextFocusedView;
    //self.selectedItem=  [[self collectionView] indexPathForCell:selectedCell];
}

- (void)getNextPage {
    if (_gettingPage) return;
    LOG_SELF;
    NSInteger nextPage = self.currentPage + 1;
    if (self.pageCount > nextPage) {
        _gettingPage = true;
        self.currentPage = nextPage;
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
        [[KBYourTube sharedInstance] apiSearch:self.filterString type:[self searchTypeForSettings] continuation:self.continuationToken completionBlock:^(KBYTSearchResults *result) {
            [SVProgressHUD dismiss];
            self.continuationToken = result.continuationToken;
            //  NSLog(@"search details: %@", searchDetails);
            if (self.currentPage == 1)
                [SVProgressHUD dismiss];
            
            [self updateSearchResults:result];
            [self.collectionView reloadDataWithCompletion:^{
                _gettingPage = false;
            }];
            
        } failureBlock:^(NSString *error) {
            [SVProgressHUD dismiss];
        }];
    }
}

#pragma mark <UICollectionViewDelegate>

// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    LOG_SELF;
    return YES;
}

// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    LOG_SELF;
    return YES;
}

- (void)playAllSearchResults:(NSArray *)searchResults {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:@[[searchResults firstObject]] completionBlock:^(NSArray *videoArray) {
        
        [SVProgressHUD dismiss];
        YTTVPlayerViewController *playerView = [[YTTVPlayerViewController alloc] initWithFrame:self.view.frame usingStreamingMediaArray:searchResults];
        [playerView addObjectsToPlayerQueue:videoArray];
        [self presentViewController:playerView animated:YES completion:nil];
        [[playerView player] play];
        NSArray *subarray = [searchResults subarrayWithRange:NSMakeRange(1, searchResults.count-1)];
        
        //NSDate *myStart = [NSDate date];
        [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:subarray completionBlock:^(NSArray *videoArray) {
            
            //TLog(@"video details fetched in %@", [myStart timeStringFromCurrentDate]);
            //TLog(@"first object: %@", subarray.firstObject);
            [playerView addObjectsToPlayerQueue:videoArray];
            
        } failureBlock:^(NSString *error) {
            
            [SVProgressHUD dismiss];
            DLog(@"failed?");
            //[self showFailureAlert:error];
        }];
        
        
    } failureBlock:^(NSString *error) {
        [SVProgressHUD dismiss];
        DLog(@"failed?");
        //[self showFailureAlert:error];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    KBYTSearchResult *searchResult = [self.searchResults objectAtIndex:indexPath.row];
    if (searchResult.resultType ==kYTSearchResultTypeVideo) {
        DLog(@"getting details for videoID: %@", searchResult.videoId);
        NSArray *subarray = [self.searchResults subarrayWithRange:NSMakeRange(indexPath.row, self.searchResults.count - indexPath.row)];
        [self playAllSearchResults:subarray];
    } else if (searchResult.resultType ==kYTSearchResultTypeChannel) {
        
        TYChannelShelfViewController *cv = [[TYChannelShelfViewController alloc] initWithChannelID:searchResult.videoId];
        [self presentViewController:cv animated:true completion:nil];
        
    } else if (searchResult.resultType ==kYTSearchResultTypePlaylist) {
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
        [[KBYourTube sharedInstance] getPlaylistVideos:searchResult.videoId completionBlock:^(KBYTPlaylist *searchDetails) {
            [SVProgressHUD dismiss];
            YTTVPlaylistViewController *playlistViewController = [YTTVPlaylistViewController playlistViewControllerWithTitle:searchResult.title backgroundColor:[UIColor blackColor] withPlaylistItems:searchDetails.videos];
            [self presentViewController:playlistViewController animated:true completion:nil];
            
        } failureBlock:^(NSString *error) {
            //
        }];
    }
}

@end
