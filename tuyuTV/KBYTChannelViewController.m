//
//  KBYTChannelViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/9/16.
//
//

#import "KBYTChannelViewController.h"
#import "YTTVStandardCollectionViewCell.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "TYTVHistoryManager.h"
#import "TYAuthUserManager.h"
#import "CollectionViewLayout.h"

@interface KBYTChannelViewController ()

@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;

@property (nonatomic, weak) IBOutlet UICollectionView * channelCollectionView;


@end

@implementation KBYTChannelViewController

@synthesize authorLabel, bannerImage, subscribersLabel, subscribers, channelTitle;

static NSString * const reuseIdentifier = @"NewStandardCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    _gettingPage = false;
    UILongPressGestureRecognizer *longpress
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongpressMethod:)];
    longpress.minimumPressDuration = .5; //seconds
    longpress.delegate = self;
    longpress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [self.channelCollectionView addGestureRecognizer:longpress];
    [self.authorLabel shadowify];
    [self.subscribersLabel shadowify];
    // Do any additional setup after loading the view.
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.currentPage = 1;
    UIImage *banner = [UIImage imageNamed:@"Banner"];
    NSURL *imageURL = [NSURL URLWithString:self.bannerURL];
    [self.bannerImage sd_setImageWithURL:imageURL placeholderImage:banner options:SDWebImageAllowInvalidSSLCertificates];
    self.authorLabel.text = self.channelTitle;
    self.subscribersLabel.text = self.subscribers;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 50;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 50;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0.0, 50.0, 0.0, 50.0);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YTTVStandardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
    [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    cell.title.text = currentItem.title;
    cell.durationLabel.text = currentItem.duration;
    // Configure the cell
    
    return cell;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    
    self.focusedCollectionCell = (UICollectionViewCell *)context.nextFocusedView;

}

- (KBYTSearchResult *)searchResultFromFocusedCell
{
    if (self.focusedCollectionCell != nil)
    {
        UICollectionView *cv = self.channelCollectionView;
        NSIndexPath *indexPath = [cv indexPathForCell:self.focusedCollectionCell];
        KBYTSearchResult *searchResult = [self.searchResults objectAtIndex:indexPath.row];
        return searchResult;
    }
    return nil;
}

- (void)promptForNewPlaylistForVideo:(KBYTSearchResult *)searchResult
{
    
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

- (void)addVideo:(KBYTSearchResult *)video toPlaylist:(NSString *)playlist
{
    DLog(@"add video: %@ to playlistID: %@", video, playlist);
    [[TYAuthUserManager sharedInstance] addVideo:video.videoId toPlaylistWithID:playlist];
}

- (void)showPlaylistAlertForSearchResult:(KBYTSearchResult *)result
{
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Video Options"
                                          message: @"Choose playlist to add video to"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    NSArray *playlistArray = [[TYAuthUserManager sharedInstance] playlists];
    
    
    __weak typeof(self) weakSelf = self;
    self.alertHandler = ^(UIAlertAction *action)
    {
        NSString *playlistID = nil;
        
        for (KBYTSearchResult *result in playlistArray)
        {
            if ([result.title isEqualToString:action.title])
            {
                playlistID = result.videoId;
            }
        }
        
        [weakSelf addVideo:result toPlaylist:playlistID];
    };
    
    for (KBYTSearchResult *result in playlistArray)
    {
        UIAlertAction *plAction = [UIAlertAction actionWithTitle:result.title style:UIAlertActionStyleDefault handler:self.alertHandler];
        [alertController addAction:plAction];
    }
    
    UIAlertAction *newPlAction = [UIAlertAction actionWithTitle:@"Create new playlist" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self promptForNewPlaylistForVideo:result];
        
    }];
    [alertController addAction:newPlAction];
    
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    
    
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}

- (void)showChannelAlertForSearchResult:(KBYTSearchResult *)result
{
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Channel Options"
                                          message: @"Subscribe to this channel?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Subscribe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [[TYAuthUserManager sharedInstance] subscribeToChannel:result.videoId];
        
    }];
    [alertController addAction:yesAction];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    [alertController addAction:yesAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}




-(void) handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer
{
    LOG_SELF;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if ([UD valueForKey:@"access_token"] == nil)
    {
        return;
    }
    
    KBYTSearchResult *searchResult = [self searchResultFromFocusedCell];
    
    NSLog(@"searchResult: %@", searchResult);
    
    switch (searchResult.resultType)
    {
        case YTSearchResultTypeVideo:
            
            [self showPlaylistAlertForSearchResult:searchResult];
            break;
            
        case YTSearchResultTypeChannel:
            
            [self showChannelAlertForSearchResult:searchResult];
            break;
            
        case YTSearchResultTypePlaylist:
            
            break;
            
        case YTSearchResultTypeUnknown:
            
            break;
    }
    
}


- (void)updateSearchResults:(NSArray *)newResults
{
    if (self.currentPage > 1)
    {
        // [[self.collectionView]
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:[[self searchResults] count]-1 inSection:0];
        [self.channelCollectionView performBatchUpdates:^{
            
            [[self searchResults] addObjectsFromArray:newResults];
            NSMutableArray *indexPathArray = [NSMutableArray new];
            NSInteger i = 0;
            for (i = 0; i < [newResults count]; i++)
            {
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:lastIndexPath.item+i inSection:0];
                [indexPathArray addObject:newIndexPath];
            }
            
            [self.channelCollectionView insertItemsAtIndexPaths:indexPathArray];
            
        } completion:^(BOOL finished) {
            
            //
        }];
        
    } else {
        self.searchResults = [newResults mutableCopy];
        [self.channelCollectionView reloadData];
        
    }
}

- (void)oldUpdateSearchResults:(NSArray *)newResults
{
    if (self.currentPage > 1)
    {
        [[self searchResults] addObjectsFromArray:newResults];
    } else {
        self.searchResults = [newResults mutableCopy];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    //check to see if we are on the last row
    NSInteger rowCount = self.searchResults.count / 5;
    NSInteger currentRow = indexPath.row / 5;
    //  NSLog(@"indexRow : %lu currentRow: %lu rowCount: %lu, searchCount: %lu", indexPath.row, currentRow, rowCount, self.searchResults.count);
    if (currentRow+1 >= rowCount)
    {
        [self getNextPage];
    }
    
}

- (void)getNextPage
{
    if (_gettingPage) return;
    NSInteger nextPage = self.currentPage + 1;
    if ([self.nextHREF length] > 0)
    {
        _gettingPage = true;
        self.currentPage = nextPage;
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
         [[KBYourTube sharedInstance] loadMoreVideosFromHREF:self.nextHREF completionBlock:^(NSDictionary *outputResults) {
            
          //    NSLog(@"search details: %@", outputResults);
          //  if (self.currentPage == 1)
                [SVProgressHUD dismiss];
            
            self.nextHREF = outputResults[@"loadMoreREF"];;
            self.totalResults = [outputResults[@"resultCount"] integerValue];
            self.pageCount = [outputResults[@"pageCount"] integerValue];
            //self.searchResults = searchDetails[@"results"];
            [self updateSearchResults:outputResults[@"results"]];
           // [self.channelCollectionView reloadData];
            _gettingPage = false;
            
        } failureBlock:^(NSString *error) {
            //
            [SVProgressHUD dismiss];
            self.nextHREF = nil;
        }];
        
    }
    
}

- (void)itemDidFinishPlaying:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
    //[[self.presentingViewController navigationController] popViewControllerAnimated:true];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //KBYTSearchResult *searchResult = [self.searchResults objectAtIndex:indexPath.row];
    //[self playFirstStreamForResult:searchResult];
    NSArray *subarray = [[self searchResults] subarrayWithRange:NSMakeRange(indexPath.row, [[self searchResults] count] - indexPath.row)];
    [self playAllSearchResults:subarray];
}

- (void)playAllSearchResults:(NSArray *)searchResults
{
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:@[[searchResults firstObject]] completionBlock:^(NSArray *videoArray) {
        
        [SVProgressHUD dismiss];
        self.playerView = [[YTKBPlayerViewController alloc] initWithFrame:self.view.frame usingStreamingMediaArray:searchResults];
        
        [self presentViewController:self.playerView animated:YES completion:nil];
        [[self.playerView player] play];
        NSArray *subarray = [searchResults subarrayWithRange:NSMakeRange(1, searchResults.count-1)];
        
        NSDate *myStart = [NSDate date];
        [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:subarray completionBlock:^(NSArray *videoArray) {
            
            NSLog(@"video details fetched in %@", [myStart timeStringFromCurrentDate]);
            [self.playerView addObjectsToPlayerQueue:videoArray];
            
        } failureBlock:^(NSString *error) {
            
        }];
        
        
    } failureBlock:^(NSString *error) {
        
    }];
}

- (void)playFirstStreamForResult:(KBYTSearchResult *)searchResult
{
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForID:searchResult.videoId completionBlock:^(KBYTMedia *videoDetails) {
        
        [SVProgressHUD dismiss];
        //[[TYTVHistoryManager sharedInstance] addVideoToHistory:[videoDetails dictionaryRepresentation]];
        NSURL *playURL = [[videoDetails.streams firstObject] url];
        AVPlayerViewController *playerView = [[AVPlayerViewController alloc] init];
        AVPlayerItem *singleItem = [AVPlayerItem playerItemWithURL:playURL];
        playerView.player = [AVQueuePlayer playerWithPlayerItem:singleItem];
        
        [self presentViewController:playerView animated:true completion:nil];
        //[[self.presentingViewController navigationController] pushViewController:playerView animated:true];
        [playerView.player play];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:singleItem];
        
        
    } failureBlock:^(NSString *error) {
        
    }];
    
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
