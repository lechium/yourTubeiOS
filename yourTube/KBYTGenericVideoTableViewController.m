//
//  KBYTGenericVideoTableViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/1/16.
//
//

#import "KBYTGenericVideoTableViewController.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import "SVProgressHUD/SVIndefiniteAnimatedView.h"
#import "KBYTSearchItemViewController.h"
#import "TYAuthUserManager.h"

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@interface KBYTGenericVideoTableViewController ()

@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;
@property (readwrite, assign) NSInteger lastStartingIndex;
@property (nonatomic, strong) NSDictionary *userData;

@end

@implementation KBYTGenericVideoTableViewController

@synthesize tableType, customTitle, customId, currentPlaybackArray;


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkAirplay];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = NO;
#if !TARGET_OS_TV
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
#endif
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = false;
    self.automaticallyAdjustsScrollViewInsets = false;
    
    self.currentPage = 1;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self updateTable];
    self.title = self.customTitle;
}

- (void)addLongPressToCell:(KBYTDownloadCell *)cell {
    UILongPressGestureRecognizer *longpress
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongpressMethod:)];
    longpress.minimumPressDuration = .5; //seconds
    //longpress.delegate = self;
    [cell addGestureRecognizer:longpress];
}

- (void)addVideo:(KBYTSearchResult *)video toPlaylist:(NSString *)playlist {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        DLog(@"add video: %@ to playlistID: %@", video, playlist);
        [[TYAuthUserManager sharedInstance] addVideo:video.videoId toPlaylistWithID:playlist];
        
    });
    
}

- (void)showPlaylistCopyAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Playlist Options"
                                          message: @"Create a copy of this playlist to your channel?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            [[TYAuthUserManager sharedInstance] copyPlaylist:result completion:^(NSString *response) {
                
                
                
                
            }];
            
            
        });
        
        
    }];
    [alertController addAction:yesAction];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
    }];
    [alertController addAction:cancelAction];
    if (self.presentedViewController != nil){
        [self.presentedViewController presentViewController:alertController animated:YES completion:nil];
    } else {
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


- (void)showPlaylistAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Video Options"
                                          message: @"Choose playlist to add video to"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    NSArray *playlistArray = [[TYAuthUserManager sharedInstance] playlists];
    //NSArray *playlistArray = @[];
    
    __weak typeof(self) weakSelf = self;
    self.alertHandler = ^(UIAlertAction *action) {
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
    
    for (KBYTSearchResult *result in playlistArray) {
        UIAlertAction *plAction = [UIAlertAction actionWithTitle:result.title style:UIAlertActionStyleDefault handler:self.alertHandler];
        [alertController addAction:plAction];
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


-(void) handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {
    LOG_SELF;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (![[KBYourTube sharedInstance] isSignedIn]) {
        DLog(@"NO ACCESS KEY");
        return;
    }
    
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    //Get the corresponding index path within the table view
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    KBYTSearchResult *result = [self.searchResults objectAtIndex:indexPath.row];
    DLog(@"result: %@", result);
    
    switch (result.resultType) {
        case kYTSearchResultTypeVideo:
            
            [self showPlaylistAlertForSearchResult:result];
            break;
            
        case kYTSearchResultTypeChannel:
            
            [self showChannelAlertForSearchResult:result];
            break;
            
        case kYTSearchResultTypePlaylist:
            
            [self showPlaylistCopyAlertForSearchResult:result];
            break;
            
        case kYTSearchResultTypeUnknown:
            
            break;
    }
    
}

- (id)initWithSearchResult:(KBYTSearchResult *)result {
    self = [super initWithStyle:UITableViewStylePlain];
    self.searchResult = result;
    return self;
}

- (id)initWithForAuthUser {
    self = [super initWithStyle:UITableViewStylePlain];
    tableType = kYTSearchResultTypeAuthUser;
    _userData = [[KBYourTube sharedInstance] userDetails];
    return self;
}

- (id)initForType:(YTSearchResultType)detailsType withTitle:(NSString *)theTitle withId:(NSString *)identifier {
    self = [super initWithStyle:UITableViewStylePlain];
    tableType = detailsType;
    customTitle = theTitle;
    customId = identifier;
    return self;
}


- (id)initForType:(YTSearchResultType)detailsType {
    self = [super initWithStyle:UITableViewStylePlain];
    tableType = detailsType;
    return self;
}

- (void)getNextPage {
    /*
    if (self.currentPage == 1 && self.searchResults.count == 0) {
        return;
    }*/
    if (self.channel.continuationToken == nil || self.playlist.continuationToken == nil) {
        return;
    }
    
    self.currentPage++;
    
    if (self.channel) {
        [[KBYourTube sharedInstance] getChannelVideosAlt:self.channel.channelID params:nil continuation:self.channel.continuationToken completionBlock:^(KBYTChannel *channel) {
            //[self.channel mergeChannelVideos:channel];
        } failureBlock:^(NSString *error) {
            
        }];
    }
    
    if (self.playlist) {
        [[KBYourTube sharedInstance] getPlaylistVideos:self.playlist.playlistID continuation:self.playlist.continuationToken completionBlock:^(KBYTPlaylist *playlist) {
            [self updateSearchResults:playlist.videos];
        } failureBlock:^(NSString *error) {
            
        }];
    }
    
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (cell.tag == kGenericLoadingCellTag) {
        [self getNextPage];
    } else {
        
        KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
        if (currentItem.resultType ==kYTSearchResultTypeVideo)
        {
            [[(KBYTDownloadCell*)cell durationLabel] setHidden:NO];
        } else {
            [[(KBYTDownloadCell*)cell durationLabel] setHidden:YES];
            
        }
    }
    
    
}

- (UITableViewCell *)loadingCell {
    UITableViewCell *cell = [[UITableViewCell alloc]
                             initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:nil];
    
    SVIndefiniteAnimatedView *indefiniteAnimatedView = [[SVIndefiniteAnimatedView alloc] initWithFrame:CGRectZero];
    indefiniteAnimatedView.strokeColor = [UIColor redColor];
    indefiniteAnimatedView.radius =  10;
    indefiniteAnimatedView.strokeThickness = 4;
    [indefiniteAnimatedView sizeToFit];
    
    indefiniteAnimatedView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    indefiniteAnimatedView.center = cell.contentView.center;
    cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:indefiniteAnimatedView];
    
    cell.tag = kGenericLoadingCellTag;
    return cell;
}

- (void)updateTable {
    [SVProgressHUD show];
    if (self.tableType == kYTSearchResultTypeChannel) {
        [[KBYourTube sharedInstance] getChannelVideosAlt:self.customId params:nil continuation:nil completionBlock:^(KBYTChannel *channel) {
            [SVProgressHUD dismiss];
            self.channel = channel;
            self.title = channel.title;
            self.searchResults = [[self.channel allSectionItems] mutableCopy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        } failureBlock:^(NSString *error) {
            TLog(@"error: %@", error);
        }];
    } else if (self.tableType == kYTSearchResultTypePlaylist) {
        [[KBYourTube sharedInstance] getPlaylistVideos:self.customId continuation:nil completionBlock:^(KBYTPlaylist *playlist) {
            [SVProgressHUD dismiss];
            self.playlist = playlist;
            self.title = playlist.title;
            self.searchResults = [[self.playlist videos] mutableCopy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        } failureBlock:^(NSString *error) {
            TLog(@"error: %@", error);
        }];
    } else if (self.tableType == kYTSearchResultTypeAuthUser) {
        __block NSMutableArray *newResults = [NSMutableArray new];
        [[KBYourTube sharedInstance] getChannelVideos:self.userData[@"channelID"] completionBlock:^(KBYTChannel *channel) {
            [newResults addObjectsFromArray:channel.allSectionItems];
            if (self.userData[@"results"]){
                [newResults addObjectsFromArray:self.userData[@"results"]];
            }
            if (self.userData[@"channels"]){
                [newResults addObjectsFromArray:self.userData[@"channels"]];
            }
            [self updateSearchResults:newResults];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.title = self.userData[@"userName"];
                [SVProgressHUD dismiss];
                [self.tableView reloadData];
            });
        } failureBlock:^(NSString *error) {
            TLog(@"error: %@", error);
        }];
    }
}


- (void)fetchPlaylistDetailsInBackground:(NSArray *)resultArray {
    //void start just by fetching the first object so we can start playing as soon as possible
    [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:@[[resultArray firstObject]] completionBlock:^(NSArray *videoArray) {
        
        
        
        //[[resultArray firstObject]setAssociatedMedia:videoDetails];
        [self showPlayAllButton];
        
        
    } failureBlock:^(NSString *error) {
        //
    }];
    
    
    
}

- (void)showPlayAllButton {
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAll)];
    self.navigationItem.rightBarButtonItem = playButton;
}

- (void)playFromIndex:(NSInteger)index {
    DLOG_SELF;
    NSArray *subarray = [self.searchResults subarrayWithRange:NSMakeRange(index, self.searchResults.count-index)];
    [self playAllSearchResults:subarray];
    
}

- (void)playAllSearchResults:(NSArray *)searchResults {
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

- (void)playAll {
    self.playerView = [[YTKBPlayerViewController alloc] initWithFrame:self.view.frame usingStreamingMediaArray:self.searchResults];
    
    [self presentViewController:self.playerView animated:YES completion:nil];
    [[self.playerView player] play];
    NSArray *subarray = [self.searchResults subarrayWithRange:NSMakeRange(1, self.searchResults.count-1)];
    
    NSDate *myStart = [NSDate date];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:subarray completionBlock:^(NSArray *videoArray) {
        
        NSLog(@"video details fetched in %@", [myStart timeStringFromCurrentDate]);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self.playerView addObjectsToPlayerQueue:videoArray];
        //[self showPlayAllButton];
        
    } failureBlock:^(NSString *error) {
        
    }];
    return;
    NSMutableArray *playerItems = [NSMutableArray new];
    for (KBYTSearchResult *result in self.searchResults) {
        if ([result media] != nil)
        {
            YTPlayerItem *playerItem = [[YTPlayerItem alloc] initWithURL:[[[[result media]streams] firstObject]url]];
            playerItem.associatedMedia = [result media];
            if (playerItem != nil)
            {
                [playerItems addObject:playerItem];
            }
        }
    }
    currentPlaybackArray = [self.searchResults mutableCopy];
    KBYTSearchResult *file = [currentPlaybackArray objectAtIndex:0];
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : file.title, MPMediaItemPropertyPlaybackDuration: [NSNumber numberWithInteger:[[file duration]timeFromDuration]] };
    [self playStreams:playerItems];
}

- (BOOL)isPlaying {
    if ([self player] != nil) {
        if (self.player.rate != 0)
        {
            return true;
        }
    }
    return false;
    
}

- (IBAction)playStreams:(NSArray *)streams {
    LOG_SELF;
    
    if ([self isPlaying] == true  ){
        return;
    }
    self.playerView = [YTKBPlayerViewController alloc];
    self.playerView.showsPlaybackControls = true;
    self.player = [AVQueuePlayer queuePlayerWithItems:streams];
    self.playerView.player = self.player;
    
    [self presentViewController:self.playerView animated:YES completion:nil];
    self.playerView.view.frame = self.view.frame;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:[streams firstObject]];
    [self.player play];
    
    
    
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    [[self player] removeItem:[[[self player] items] firstObject]];
    [currentPlaybackArray removeObjectAtIndex:0];
    if ([[self.player items] count] == 0) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [self dismissViewControllerAnimated:true completion:nil];
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    } else {
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:[[[self player] items] firstObject]];
        KBYTSearchResult *file = [currentPlaybackArray objectAtIndex:0];
        
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : file.title, MPMediaItemPropertyPlaybackDuration: [NSNumber numberWithInteger:[[file duration]timeFromDuration]] };//, MPMediaItemPropertyArtwork: artwork };
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([self.nextHREF length] > 0) {
        return self.searchResults.count + 1;
    }
    return self.searchResults.count;
    
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    tableView.backgroundColor = [UIColor whiteColor];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (void)updateSearchResults:(NSArray *)newResults {
    if (self.currentPage > 1) {
        if (self.searchResults == nil) {
            self.searchResults = [NSMutableArray new];
        }
        [[self searchResults] addObjectsFromArray:newResults];
    } else {
        self.searchResults = [newResults mutableCopy];
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    if (indexPath.row >= self.searchResults.count){
        return [self loadingCell];
    }
    
    KBYTDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[KBYTDownloadCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    if ([currentItem.author length] == 0) {
        cell.detailTextLabel.text = self.customTitle;
    } else {
        cell.detailTextLabel.text = currentItem.author;
        
    }
    cell.textLabel.text = currentItem.title;
    
    
    
    if (currentItem.resultType !=kYTSearchResultTypeVideo) {
        cell.views = currentItem.details;
        cell.duration = nil;
    } else {
        cell.duration = currentItem.duration;
        
        NSNumberFormatter *numFormatter = [NSNumberFormatter new];
        numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        NSNumber *view_count = [numFormatter numberFromString:currentItem.views];
        
        cell.views = [[numFormatter stringFromNumber:view_count] stringByAppendingString:@" Views"];
    }
    
    if (currentItem.resultType ==kYTSearchResultTypeChannel) {
        cell.views = @"";
    }
    
    
    cell.downloading = false;
    NSString *secPath = [currentItem.imagePath stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    NSURL *imageURL = [NSURL URLWithString:secPath];
    
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceHolderImage"];
    // UIImage *theImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"YTPlaceHolderImage" ofType:@"png"]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    cell.imageView.autoresizingMask = ( UIViewAutoresizingNone );
    [cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    [self addLongPressToCell:cell];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[self tableView] deselectRowAtIndexPath:indexPath animated:false];
    if (indexPath.row >= self.searchResults.count) {
        return; //selected the spinner item, jerks.
    }
    KBYTSearchResult *currentResult = [self.searchResults objectAtIndex:indexPath.row];
    
    if (currentResult.resultType == kYTSearchResultTypeChannel) {
        
        KBYTGenericVideoTableViewController *genericTableView = [[KBYTGenericVideoTableViewController alloc] initForType:kYTSearchResultTypeChannel withTitle:currentResult.title withId:currentResult.videoId];
        [[self navigationController] pushViewController:genericTableView animated:true];
        return;
    } else if (currentResult.resultType == kYTSearchResultTypePlaylist) {
        
        KBYTGenericVideoTableViewController *genericTableView = [[KBYTGenericVideoTableViewController alloc] initForType:currentResult.resultType withTitle:currentResult.title withId:currentResult.videoId];
        [[self navigationController] pushViewController:genericTableView animated:true];
        return;
    }
    
    if ([currentResult media] != nil) {
        KBYTSearchItemViewController *searchItem = [[KBYTSearchItemViewController alloc] initWithMedia:[currentResult media]];
        searchItem.delegate = self;
        searchItem.index = indexPath.row;
        [[self navigationController] pushViewController:searchItem animated:true];
        return;
    }
    //[SVProgressHUD showInfoWithStatus:@"Fetching details"];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForID:currentResult.videoId completionBlock:^(KBYTMedia *videoDetails) {
        
        
        [SVProgressHUD dismiss];
        KBYTSearchItemViewController *searchItem = [[KBYTSearchItemViewController alloc] initWithMedia:videoDetails];
        searchItem.delegate = self;
        searchItem.index = indexPath.row;
        [[self navigationController] pushViewController:searchItem animated:true];
        
    } failureBlock:^(NSString *error) {
        
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Failed to get video details" message:error delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [SVProgressHUD dismiss];
        [errorAlert show];
    }];
    
    //[self getVideoIDDetails:currentResult.videoId];
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
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



- (void)checkAirplay {
#if TARGET_OS_IOS
    NSInteger status = [[KBYourTube sharedInstance] airplayStatus];
    
    if (status == 0) {
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.airplayTimer invalidate];
    } else {
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self populateToolbar:status];
        if (![self.airplayTimer isValid])
        {
            [self fireAirplayTimer];
        }
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            NSDictionary *playbackInfo = [self getAirplayDetails];
            CGFloat duration = [[playbackInfo valueForKey:@"duration"] floatValue];
            CGFloat position = [[playbackInfo valueForKey:@"position"] floatValue];
            CGFloat percent = position / duration;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.airplayProgressPercent = percent;
                self.airplaySlider.value = percent;
                self.airplayDuration = duration;
            });
        }
    });
#endif
}

- (void)fireAirplayTimer {
    self.airplayTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkAirplay) userInfo:nil repeats:TRUE];
}

#define FLEXY                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]

- (void)sliderMoved:(UISlider *)slider {
    
    CGFloat translatedSpot = self.airplayDuration * slider.value;
    [self scrubToPosition:translatedSpot];
}

- (void)populateToolbar:(NSInteger)status {
#if TARGET_OS_IOS
    self.sliderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
    self.airplaySlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, 220, 40)];
    self.airplaySlider.value = self.airplayProgressPercent;
    [self.airplaySlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    [self.sliderView addSubview:self.airplaySlider];
    
    UIBarButtonItem *sliderItem = [[UIBarButtonItem alloc] initWithCustomView:self.sliderView];
    
    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:[KBYourTube sharedInstance] action:@selector(stopAirplay)];
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:[KBYourTube sharedInstance] action:@selector(pauseAirplay)];
    if (status == 1) //playing
        playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:[KBYourTube sharedInstance] action:@selector(pauseAirplay)];
    UIBarButtonItem *fixSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixSpace.width = 10.0f;
    self.toolbarItems = @[FLEXY,stopButton, fixSpace,playButton, fixSpace, sliderItem, FLEXY];
#endif
}


- (NSDictionary *)returnFromURLRequest:(NSString *)requestString requestType:(NSString *)type {
    NSURL *deviceURL = [NSURL URLWithString:requestString];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:deviceURL];
    [request setHTTPMethod:type];
    [request addValue:@"MediaControl/1.0" forHTTPHeaderField:@"User-Agent"];
    NSURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    //NSLog(@"return details: %@", datString);
    return [datString dictionaryValue];
}

- (NSDictionary *)scrubToPosition:(CGFloat)position {
    NSString *requestString = [NSString stringWithFormat:@"http://%@/scrub?position=%f", [[KBYourTube sharedInstance] airplayIP], position];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"POST"];
    //  NSLog(@"returnDict: %@", returnDict);
    return returnDict;
    
    //   /scrub?position=20.097000
}

- (NSDictionary *)getAirplayDetails {
    NSString *requestString = [NSString stringWithFormat:@"http://%@/playback-info", [[KBYourTube sharedInstance] airplayIP]];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"GET"];
    //    NSLog(@"returnDict: %@", returnDict);
    return returnDict;
}



@end
