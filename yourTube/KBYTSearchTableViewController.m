//
//  KBYTSearchTableViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/1/16.
//
//

#import "KBYTSearchTableViewController.h"
#import "OurViewController.h"

#define kLoadingCellTag 500

@implementation YTKBPlayerViewController

- (BOOL)shouldAutorotate
{
    return TRUE;
}

@end

@interface KBYTActualSearchResultsTableViewController : UITableViewController
@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;
@property (readwrite, assign) NSInteger currentPage;
@property (readwrite, assign) NSInteger lastStartingIndex;

- (void)updateSearchResults:(NSArray *)newResults;

@end

@implementation KBYTActualSearchResultsTableViewController

- (UITableViewCell *)loadingCell {
    UITableViewCell *cell = [[UITableViewCell alloc]
                             initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:nil];
    
    UIActivityIndicatorView *activityIndicator =
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = cell.center;
    [cell addSubview:activityIndicator];
    
    [activityIndicator startAnimating];
    
    cell.tag = kLoadingCellTag;
    
    return cell;
}

- (void)updateSearchResults:(NSArray *)newResults
{
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
        //_currentPage++;
        KBYTSearchTableViewController *pvc = (KBYTSearchTableViewController *)[self presentingViewController];
        [pvc getNextPage];
    }
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.currentPage < self.pageCount)
    {
        return self.searchResults.count + 1;
    }
    return self.searchResults.count;
    
}

- (void)willPresentSearchController:(UISearchController *)searchController
{
    LOG_SELF;
}
- (void)didPresentSearchController:(UISearchController *)searchController
{
    LOG_SELF;
}
- (void)willDismissSearchController:(UISearchController *)searchController {
    LOG_SELF;
}
- (void)didDismissSearchController:(UISearchController *)searchController
{
    LOG_SELF;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KBYTSearchResult *currentResult = [self.searchResults objectAtIndex:indexPath.row];
    KBYTSearchTableViewController *pvc = (KBYTSearchTableViewController *)[self presentingViewController];
    [pvc getVideoIDDetails:currentResult.videoId];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    if (indexPath.row >= self.searchResults.count) {
        return [self loadingCell];
    }
    KBYTDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[KBYTDownloadCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.detailTextLabel.text = currentItem.author;
    cell.textLabel.text = currentItem.title;
    cell.downloading = false;
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceHolderImage"];
    // UIImage *theImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"YTPlaceHolderImage" ofType:@"png"]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    cell.imageView.autoresizingMask = ( UIViewAutoresizingNone );
    [cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    return cell;
}

@end

@interface KBYTSearchTableViewController () <UISearchResultsUpdating, UISearchBarDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;
@property (readwrite, assign) NSInteger lastStartingIndex;

@property (nonatomic, strong) KBYTActualSearchResultsTableViewController *viewController;
@end

@implementation KBYTSearchTableViewController

@synthesize delegate;

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self resetSearchResults];
}

- (void)resetSearchResults
{
    self.currentPage = 1;
    self.totalResults = 0;
    self.pageCount = 0;
    [self.searchResults removeAllObjects];
    UINavigationController *navController = (UINavigationController *)self.searchController.searchResultsController;
    
    KBYTActualSearchResultsTableViewController *vc = (KBYTActualSearchResultsTableViewController *)navController.topViewController;
    vc.currentPage = 1;
    vc.totalResults = 0;
    vc.pageCount = 0;
    [vc.searchResults removeAllObjects];
    [vc.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self resetSearchResults];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar
{
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.viewController = [[KBYTActualSearchResultsTableViewController alloc] init];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UINavigationController *searchResultsController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    
    self.searchController.searchResultsUpdater = self;
    // self.searchController.hidesNavigationBarDuringPresentation = false;
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y + 64, self.searchController.searchBar.frame.size.width, 44.0);
    self.searchController.searchBar.delegate = self;
    self.searchController.definesPresentationContext = true;
    //self.searchController.dimsBackgroundDuringPresentation = false;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
    self.currentPage = 1;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.title = @"YouTube Search";
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

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

- (void)getNextPage
{
    LOG_SELF;
    NSInteger nextPage = self.currentPage + 1;
    if (self.pageCount > nextPage)
    {
        self.currentPage = nextPage;
        [self updateSearchResultsForSearchController:self.searchController];
    }
    
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    LOG_SELF;
    NSString *searchString = [self.searchController.searchBar text];
    [[KBYourTube sharedInstance] youTubeSearch:searchString pageNumber:self.currentPage completionBlock:^(NSDictionary *searchDetails) {
        /*
         self.searchResults = searchDetails[@"results"];
         //vc.currentPage = self.currentPage;
         //[vc updateSearchResults:self.searchResults];
         //vc.searchResults = self.searchResults;
         self.totalResults = [searchDetails[@"resultCount"] integerValue];
         self.pageCount = [searchDetails[@"pageCount"] integerValue];
         [self.tableView reloadData];
         */
        // NSLog(@"searchDetails: %@", searchDetails);
        if (self.searchController.searchResultsController) {
            UINavigationController *navController = (UINavigationController *)self.searchController.searchResultsController;
            
            KBYTActualSearchResultsTableViewController *vc = (KBYTActualSearchResultsTableViewController *)navController.topViewController;
            
            
            self.totalResults = [searchDetails[@"resultCount"] integerValue];
            self.pageCount = [searchDetails[@"pageCount"] integerValue];
            self.searchResults = searchDetails[@"results"];
            //vc.searchResults = self.searchResults;
            vc.totalResults = self.totalResults;
            vc.currentPage = self.currentPage;
            vc.pageCount = self.pageCount;
            [vc updateSearchResults:self.searchResults];
            [vc.tableView reloadData];
            
        }
        
        
    } failureBlock:^(NSString *error) {
        //
        
    }];
    
    
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
    
    return 0;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    tableView.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell *)loadingCell {
    UITableViewCell *cell = [[UITableViewCell alloc]
                             initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:nil];
    
    UIActivityIndicatorView *activityIndicator =
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = cell.center;
    [cell addSubview:activityIndicator];
    
    [activityIndicator startAnimating];
    
    cell.tag = kLoadingCellTag;
    
    return cell;
}


//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 100;
//}
/*
 - (void)tableView:(UITableView *)tableView
 willDisplayCell:(UITableViewCell *)cell
 forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (cell.tag == kLoadingCellTag) {
 _currentPage++;
 [self getNextPage];
 }
 }
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    /*
     if (indexPath.row > self.searchResults.count){
     return [self loadingCell];
     }
     */
    KBYTDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[KBYTDownloadCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.detailTextLabel.text = currentItem.author;
    cell.textLabel.text = currentItem.title;
    cell.downloading = false;
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceHolderImage"];
    // UIImage *theImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"YTPlaceHolderImage" ofType:@"png"]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    cell.imageView.autoresizingMask = ( UIViewAutoresizingNone );
    [cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    return cell;
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

//transplants from ourviewcontroller


- (void)checkAirplay
{
    NSInteger status = [[KBYourTube sharedInstance] airplayStatus];
    
    if (status == 0) {
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.airplayTimer invalidate];
    } else {
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self populateToolbar:status];
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
}

- (void)fireAirplayTimer
{
    self.airplayTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkAirplay) userInfo:nil repeats:TRUE];
}

#define FLEXY                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]

- (void)sliderMoved:(UISlider *)slider
{
    CGFloat translatedSpot = self.airplayDuration * slider.value;
    [self scrubToPosition:translatedSpot];
}

- (void)populateToolbar:(NSInteger)status
{
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
}


- (NSDictionary *)returnFromURLRequest:(NSString *)requestString requestType:(NSString *)type
{
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

- (NSDictionary *)scrubToPosition:(CGFloat)position
{
    NSString *requestString = [NSString stringWithFormat:@"http://%@/scrub?position=%f", [self airplayIP], position];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"POST"];
    //  NSLog(@"returnDict: %@", returnDict);
    return returnDict;
    
    //   /scrub?position=20.097000
}

- (NSDictionary *)getAirplayDetails
{
    NSString *requestString = [NSString stringWithFormat:@"http://%@/playback-info", [self airplayIP]];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"GET"];
    //    NSLog(@"returnDict: %@", returnDict);
    return returnDict;
}

//the action sheet result handler
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.previousVideoID = nil;
    KBYTStream *chosenStream = nil;
    NSInteger airplayIndex = 0;
    APDeviceController *deviceController = nil;
    int deviceType;
    switch (buttonIndex) {
        case 0: //Play video
            
            chosenStream = [[self.currentMedia streams] objectAtIndex:0];
            [self playStream:chosenStream];
            break;
            
        case 1: //download video
            
            chosenStream = [[self.currentMedia streams] objectAtIndex:0];
            [self downloadStream:chosenStream];
            break;
            
        case 2: //download audio
            
            chosenStream = [[self.currentMedia streams] lastObject];
            [self downloadStream:chosenStream];
            break;
            
        default:
            
            if (buttonIndex == actionSheet.cancelButtonIndex)
            {
                return;
            }
            
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            NSString *isolatedTitle = [[buttonTitle componentsSeparatedByString:@" "] lastObject];
            if ([buttonTitle containsString:@"AirPlay"])
            {
                isolatedTitle = [[buttonTitle componentsSeparatedByString:@"AirPlay to "] lastObject];
                deviceType = 0;
            } else {
                isolatedTitle = [[buttonTitle componentsSeparatedByString:@"Play in YouTube on "] lastObject];
                deviceType = 1;
            }
            chosenStream = [[self.currentMedia streams] objectAtIndex:0];
            //need to adjust the index to subtract the three objects above us to get the proper device index
            airplayIndex = buttonIndex - 3;
            deviceController = [[KBYourTube sharedInstance] deviceController];
            self.airplayIP = [deviceController deviceIPFromName:isolatedTitle andType:deviceType];
            
            if (deviceType == 0) //airplay
            {
                
                [[KBYourTube sharedInstance] airplayStream:chosenStream ToDeviceIP:self.airplayIP ];
                [self fireAirplayTimer];
            } else {
                
                //aircontrol
                [[KBYourTube sharedInstance] playMedia:self.currentMedia ToDeviceIP:self.airplayIP];
            }
    }
}

//play the import completion sound (standard tri-tone success sound)
+ (void)playCompleteSound
{
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"complete" ofType:@"aif"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: thePath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

//action sheet that is shown to allow the user to choose whether or not to download video / audio or play the video


- (void)showActionSheet
{
    
    NSArray *airplayDevices = [[[KBYourTube sharedInstance] deviceController] airplayServers];
    
    NSString *actionSheetTitle = [NSString stringWithFormat:@"Choose action for %@", self.currentMedia.title];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    
    [actionSheet setTitle:actionSheetTitle];
    [actionSheet setDelegate:self];
    [actionSheet addButtonWithTitle:@"Play video"];
    [actionSheet addButtonWithTitle:@"Download Video"];
    [actionSheet addButtonWithTitle:@"Download Audio"];
    for (NSNetService *service in airplayDevices)
    {
        NSString *playTitle = nil;
        if ([[service type] isEqualToString:@"_aircontrol._tcp."])
        {
            playTitle = [NSString stringWithFormat:@"Play in YouTube on %@", [service name]];
        } else {
            playTitle = [NSString stringWithFormat:@"AirPlay to %@", [service name]];
        }
        [actionSheet addButtonWithTitle:playTitle];
    }
    [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet setCancelButtonIndex:3+[airplayDevices count]];
    
    //UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:names, nil];
    
    [actionSheet showInView:self.view];
}

//actually get the video details for the selected video.

- (void)getVideoIDDetails:(NSString *)details
{
    [[KBYourTube sharedInstance] getVideoDetailsForID:details completionBlock:^(KBYTMedia *videoDetails) {
        
        NSLog(@"got details successfully: %@", videoDetails);
        self.currentMedia = videoDetails;
        self.previousVideoID = videoDetails.videoId;
        self.gettingDetails = false;
        [self showActionSheet]; //show the action sheet
        
    } failureBlock:^(NSString *error) {
        
        NSLog(@"fail!: %@", error);
        
    }];
}



- (BOOL)isPlaying
{
    if ([self player] != nil)
    {
        if (self.player.rate != 0)
        {
            return true;
        }
    }
    return false;
    
}

- (void)showPlayerview
{
    if ([self player] != nil)
    {
        if (self.player.rate != 0)
        {
            [[self delegate] pushViewController:self.playerView];
            return;
        }
    }
    
    
}


- (void)playFile:(NSDictionary *)file
{
    NSString *outputFile = [[self downloadFolder] stringByAppendingPathComponent:file[@"outputFilename"]];
    NSURL *playURL = [NSURL fileURLWithPath:outputFile];
    //NSLog(@"play url: %@", playURL);
    if ([self isPlaying] == true  ){
        return;
    }
    self.playerView = [YTKBPlayerViewController alloc];
    self.playerView.showsPlaybackControls = true;
    self.player = [AVPlayer playerWithURL:playURL];
    self.playerView.player = self.player;
    
    [self presentViewController:self.playerView animated:YES completion:nil];
    self.playerView.view.frame = self.view.frame;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player];
    
    [self.player play];
    
}

//play the video stream
- (IBAction)playStream:(KBYTStream *)stream
{
    NSURL *playURL = [stream url];
    //NSLog(@"play url: %@", playURL);
    if ([self isPlaying] == true  ){
        return;
    }
    self.playerView = [YTKBPlayerViewController alloc];
    self.playerView.showsPlaybackControls = true;
    self.player = [AVPlayer playerWithURL:playURL];
    self.playerView.player = self.player;
    
    [self presentViewController:self.playerView animated:YES completion:nil];
    self.playerView.view.frame = self.view.frame;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player];
    
    [self.player play];
    
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player];
}

- (NSString *)appSupportFolder
{
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *outputFolder = @"/var/mobile/Library/Application Support/tuyu";
    if (![man fileExistsAtPath:outputFolder])
    {
        [man createDirectoryAtPath:outputFolder withIntermediateDirectories:true attributes:nil error:nil];
    }
    return outputFolder;
}

- (NSString *)downloadFolder
{
    return [[self appSupportFolder] stringByAppendingPathComponent:@"Downloads"];
}

- (void)updateDownloadsDictionary:(NSDictionary *)streamDictionary
{
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *dlplist = [[self appSupportFolder] stringByAppendingPathComponent:@"Downloads.plist"];
    NSMutableArray *currentArray = nil;
    if ([man fileExistsAtPath:dlplist])
    {
        currentArray = [[NSMutableArray alloc] initWithContentsOfFile:dlplist];
    } else {
        currentArray = [NSMutableArray new];
    }
    [currentArray addObject:streamDictionary];
    [currentArray writeToFile:dlplist atomically:true];
}

//offload the downloading into the mobile substrate tweak so it can run in the background without timing out.

- (void)downloadStream:(KBYTStream *)stream
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSMutableDictionary *streamDict = [[stream dictionaryValue] mutableCopy];
    streamDict[@"duration"] = self.currentMedia.duration;
    streamDict[@"author"] = self.currentMedia.author;
    streamDict[@"images"] = self.currentMedia.images;
    streamDict[@"inProgress"] = [NSNumber numberWithBool:true];
    streamDict[@"videoId"] = self.currentMedia.videoId;
    NSString *stringURL = [[stream url] absoluteString];
    streamDict[@"url"] = stringURL;
    [self updateDownloadsDictionary:streamDict];
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.importscience"];
    [center sendMessageName:@"org.nito.importscience.addDownload" userInfo:streamDict];
}


@end
