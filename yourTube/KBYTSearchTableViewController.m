//
//  KBYTSearchTableViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/1/16.
//
//

#import "KBYTSearchTableViewController.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import "SVProgressHUD/SVIndefiniteAnimatedView.h"
#import "KBYTSearchItemViewController.h"
#import "KBYTGenericVideoTableViewController.h"
#import "TYAuthUserManager.h"
#import "UIView+RecursiveFind.h"

#define kLoadingCellTag 500

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@interface KBYTSearchTableViewController () <UISearchResultsUpdating, UISearchBarDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;
@property (readwrite, assign) NSInteger lastStartingIndex;
@property (nonatomic, strong) NSString *continuationToken;

@end

@implementation KBYTSearchTableViewController

- (void)forceShowScopeView {
    NSString *nombre = [@[@"_UIS", @"earc",@"hBar",@"Scope",@"Contai",@"nerView"] componentsJoinedByString:@""];
    UIView *view = [self.searchController.searchBar findFirstSubviewWithClass:NSClassFromString(nombre)];
    if (!view) {
        view = [self.searchController.searchBar valueForKey:[@[@"_sc",@"opeB",@"arCo",@"ntain",@"erView"] componentsJoinedByString:@""]];
    }
    view.hidden = false;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    // [self resetSearchResults];
    [self forceShowScopeView];
    
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

- (void)resetSearchResults {
    self.currentPage = 1;
    self.totalResults = 0;
    self.pageCount = 0;
    self.continuationToken = nil;
    [self.searchResults removeAllObjects];
    [self.tableView reloadData];
    [self forceShowScopeView];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    LOG_SELF;
    self.showingSuggestedVideos = false;
    self.navigationItem.title = @"YouTube Search";
    NSString *searchString = [self.searchController.searchBar text];
    self.lastSearch = searchString;
    [[KBYourTube sharedInstance] setLastSearch:self.lastSearch];
    //NSLog(@"search string: %@", searchString);
    if (self.currentPage == 1)
        [SVProgressHUD show];
    
    [[KBYourTube sharedInstance] apiSearch:searchString type:[self searchTypeForSettings] continuation:self.continuationToken completionBlock:^(KBYTSearchResults *result) {
        
        //NSLog(@"[yourTubeiOS] result: %@", result.videos);
        if (self.currentPage == 1)
            [SVProgressHUD dismiss];
        [self updateSearchResults:result.allItems];
        self.continuationToken = result.continuationToken;
        //[self.searchResults addObjectsFromArray:result.videos];
        [self.tableView reloadData];
    } failureBlock:^(NSString *error) {
        [SVProgressHUD dismiss];
    }];
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self resetSearchResults];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {
    
}


- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    self.continuationToken = nil;
    self.currentPage = 1;
    NSString *scope = searchBar.scopeButtonTitles[selectedScope];
    DLog(@"scope changed: %lu: %@", selectedScope, scope);
    [[KBYourTube sharedUserDefaults] setValue:scope forKey:@"filterType"];
    [self searchBarSearchButtonClicked:searchBar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.searchController dismissViewControllerAnimated:false completion:nil];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"last search: %@", self.lastSearch);
    if (self.lastSearch != nil)
    {
        self.showingSuggestedVideos = false;
        //   self.searchController.searchBar.text = self.lastSearch;
        // [self searchBarSearchButtonClicked:self.searchController.searchBar];
    } else {
        self.lastSearch = [[KBYourTube sharedInstance] lastSearch];
        if (self.lastSearch != nil)
        {
            self.searchController.searchBar.text = self.lastSearch;
            [self searchBarSearchButtonClicked:self.searchController.searchBar];
            self.navigationItem.title = @"YouTube Search";
        }
        
    }
    
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
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    
    self.searchController.searchResultsUpdater = self;
    self.searchController.hidesNavigationBarDuringPresentation = false;
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    self.searchController.searchBar.delegate = self;
    self.searchController.definesPresentationContext = true;
#if !TARGET_OS_TV
    self.searchController.dimsBackgroundDuringPresentation = false;
#endif
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
#if TARGET_OS_TV
    
    //NEVER DO THE BELOW LINE, LEFT AS REMINDER
    self.definesPresentationContext = YES;
    
    //[self.view addSubview:self.searchController.searchBar];
    //[self.searchController.searchBar becomeFirstResponder];
#endif
    self.searchController.searchBar.showsScopeBar = true;
    self.searchController.searchBar.scopeButtonTitles = @[@"All", @"Channels", @"Playlists"];
    self.currentPage = 1;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.title = @"YouTube Search";
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}



//- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
//
//    self.navigationController.navigationBar.translucent = YES;
//}
//
//- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
//    self.navigationController.navigationBar.translucent = NO;
//
//}

/*
 - (void) viewDidLayoutSubviews
 {
 if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
 {
 CGRect viewBounds = self.view.bounds;
 CGFloat topBarOffset = self.topLayoutGuide.length;
 viewBounds.origin.y = topBarOffset * -1;
 self.view.bounds = viewBounds;
 }
 }
 */
- (void)getNextPage {
    
    NSInteger nextPage = self.currentPage + 1;
    if (self.continuationToken != nil) {
        self.currentPage = nextPage;
        //[self updateSearchResultsForSearchController:self.searchController];
        [self searchBarSearchButtonClicked:self.searchController.searchBar];
    }
    
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    //no longer do anything here because it would mess up paging functionality, revisit some day.
    //LOG_SELF;
#if TARGET_OS_TV
    [self searchBarSearchButtonClicked:self.searchController.searchBar];
#endif
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
    
    //if (self.currentPage < self.pageCount) {
    if (self.continuationToken != nil) {
        return self.searchResults.count + 1;
    }
    return self.searchResults.count;
    
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    tableView.backgroundColor = [UIColor whiteColor];
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
    
    cell.tag = kLoadingCellTag;
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}
- (void)updateSearchResults:(NSArray *)newResults {
    if (self.currentPage > 1)
    {
        [[self searchResults] addObjectsFromArray:newResults];
    } else {
        
        self.searchResults = [newResults mutableCopy];
    }
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (cell.tag == kLoadingCellTag) {
        [self getNextPage];
    }
}

- (void)addLongPressToCell:(KBYTDownloadCell *)cell {
    UILongPressGestureRecognizer *longpress
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongpressMethod:)];
    longpress.minimumPressDuration = .5; //seconds
    longpress.delegate = self;
    [cell addGestureRecognizer:longpress];
}

- (void)addVideo:(KBYTSearchResult *)video toPlaylist:(NSString *)playlist {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        DLog(@"add video: %@ to playlistID: %@", video, playlist);
        [[TYAuthUserManager sharedInstance] addVideo:video.videoId toPlaylistWithID:playlist];
        
    });
    
}


- (void)showPlaylistAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Video Options"
                                          message: @"Choose playlist to add video to"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    DLog(@"long press: %@", result);
    
    NSArray *playlistArray = [[TYAuthUserManager sharedInstance] playlists];
    //NSArray *playlistArray = @[];
    
    // __weak typeof(self) weakSelf = self;
    self.alertHandler = ^(UIAlertAction *action)
    {
        NSString *playlistID = nil;
        
        for (KBYTSearchResult *playlist in playlistArray)
        {
            if ([playlist.title isEqualToString:action.title])
            {
                playlistID = playlist.videoId;
            }
        }
        
        [self addVideo:result toPlaylist:playlistID];
    };
    
    for (KBYTSearchResult *result in playlistArray)
    {
        UIAlertAction *plAction = [UIAlertAction actionWithTitle:result.title style:UIAlertActionStyleDefault handler:self.alertHandler];
        [alertController addAction:plAction];
    }
    
    UIAlertAction *subscribeToChannel = [UIAlertAction actionWithTitle:@"Subscribe to Video's channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([result channelId] != nil && ![[result channelId] isEqualToString:@"Unavailable"])
        {
            DLog(@"subscribing to channel: %@", result.channelId);
            [[TYAuthUserManager sharedInstance] subscribeToChannel:result.channelId];
        } else {
            /*
             [[KBYourTube sharedInstance] getUserVideos:result.channelPath.lastPathComponent completionBlock:^(NSDictionary *searchDetails) {
             
             
             DLog(@"subscribing to channel: %@", searchDetails[@"channelID"]);
             [[TYAuthUserManager sharedInstance] subscribeToChannel:searchDetails[@"channelID"]];
             } failureBlock:^(NSString *error) {
             //
             }];
             */
        }
        
    }];
    
    [alertController addAction:subscribeToChannel];
    
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
    if (self.presentedViewController != nil){
        [self.presentedViewController presentViewController:alertController animated:YES completion:nil];
    } else {
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


-(void) handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {
    LOG_SELF;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (![[KBYourTube sharedInstance] isSignedIn])
    {
        DLog(@"NO ACCESS KEY");
        return;
    }
    
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    //Get the corresponding index path within the table view
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    KBYTSearchResult *result = [self.searchResults objectAtIndex:indexPath.row];
    DLog(@"result: %@", result);
    
    switch (result.resultType)
    {
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    if (indexPath.row >= self.searchResults.count){
        return [self loadingCell];
    }
    
    KBYTDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[KBYTDownloadCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [self addLongPressToCell:cell];
    
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.detailTextLabel.text = currentItem.author;
    cell.textLabel.text = currentItem.title;
    cell.duration = currentItem.duration;
    
    NSNumberFormatter *numFormatter = [NSNumberFormatter new];
    numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    if (currentItem.resultType !=kYTSearchResultTypeVideo)
    {
        cell.views = currentItem.details;
    } else {
        NSNumber *view_count = [numFormatter numberFromString:currentItem.views];
        cell.views = [[numFormatter stringFromNumber:view_count] stringByAppendingString:@" Views"];
        
    }
    
    cell.downloading = false;
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceHolderImage"];
    // UIImage *theImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"YTPlaceHolderImage" ofType:@"png"]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    cell.imageView.autoresizingMask = ( UIViewAutoresizingNone );
    [cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[self tableView] deselectRowAtIndexPath:indexPath animated:false];
    if (indexPath.row >= self.searchResults.count)
    {
        return; //selected the spinner item, jerks.
    }
    KBYTSearchResult *currentResult = [self.searchResults objectAtIndex:indexPath.row];
    //[SVProgressHUD showInfoWithStatus:@"Fetching details"];
    [SVProgressHUD show];
    
    if (currentResult.resultType == kYTSearchResultTypeVideo)
    {
        [[KBYourTube sharedInstance] getVideoDetailsForID:currentResult.videoId completionBlock:^(KBYTMedia *videoDetails) {
            
            //
            [SVProgressHUD dismiss];
            KBYTSearchItemViewController *searchItem = [[KBYTSearchItemViewController alloc] initWithMedia:videoDetails];
#if TARGET_OS_TV
            [self presentViewController:searchItem animated:true completion:nil];
#else
            [[self navigationController] pushViewController:searchItem animated:true];
#endif
        } failureBlock:^(NSString *error) {
            
            [SVProgressHUD dismiss];
            
        }];
    } else if (currentResult.resultType == kYTSearchResultTypeChannel)
    {
        
        KBYTGenericVideoTableViewController *genericTableView = [[KBYTGenericVideoTableViewController alloc] initForType:kYTSearchResultTypeChannel withTitle:currentResult.title withId:currentResult.videoId];
        [[self navigationController] pushViewController:genericTableView animated:true];
        
    } else if (currentResult.resultType == kYTSearchResultTypePlaylist)
    {
        
        KBYTGenericVideoTableViewController *genericTableView = [[KBYTGenericVideoTableViewController alloc] initForType:kYTSearchResultTypePlaylist withTitle:currentResult.title withId:currentResult.videoId];
        [[self navigationController] pushViewController:genericTableView animated:true];
        
    }
    //[self getVideoIDDetails:currentResult.videoId];
}



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
