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


@interface KBYTGenericVideoTableViewController ()

@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;
@property (readwrite, assign) NSInteger lastStartingIndex;

@end

@implementation KBYTGenericVideoTableViewController

@synthesize tableType;


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
   // [self checkAirplay];
}

- (void)viewDidLoad {
    [super viewDidLoad];
  
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.edgesForExtendedLayout = UIRectEdgeNone;
 
    self.tableView.translatesAutoresizingMaskIntoConstraints = false;
    self.automaticallyAdjustsScrollViewInsets = false;
    
    self.currentPage = 1;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self updateTableForType:self.tableType];
}

- (id)initForType:(NSInteger)detailsType
{
    self = [super initWithStyle:UITableViewStylePlain];
    tableType = detailsType;
    return self;
}

- (void)updateTableForType:(NSInteger)type
{
    [SVProgressHUD show];
    if (type == 0) //featured
    {
        self.navigationItem.title = @"Suggested Videos";
        [[KBYourTube sharedInstance] getFeaturedVideosWithCompletionBlock:^(NSDictionary *searchDetails) {
            
            self.currentPage = 1;
            [SVProgressHUD dismiss];
            self.totalResults = [searchDetails[@"resultCount"] integerValue];
            self.pageCount = [searchDetails[@"pageCount"] integerValue];
            [self updateSearchResults:searchDetails[@"results"]];
            [self.tableView reloadData];
       
            
        } failureBlock:^(NSString *error) {
            [SVProgressHUD dismiss];
            
        }];
    } else if (type == 1) //popular
    {
         self.navigationItem.title = @"#PopularOnYouTube";
        [[KBYourTube sharedInstance] getChannelVideos:KBYTPopularChannelID completionBlock:^(NSDictionary *searchDetails) {
            
            self.currentPage = 1;
            [SVProgressHUD dismiss];
            self.totalResults = [searchDetails[@"resultCount"] integerValue];
            self.pageCount = [searchDetails[@"pageCount"] integerValue];
            [self updateSearchResults:searchDetails[@"results"]];
            [self.tableView reloadData];
            
        } failureBlock:^(NSString *error) {
            [SVProgressHUD dismiss];
            
        }];
    }  else if (type == 2) //music
    {
         self.navigationItem.title = @"#Music";
        [[KBYourTube sharedInstance] getChannelVideos:KBYTMusicChannelID completionBlock:^(NSDictionary *searchDetails) {
            
            self.currentPage = 1;
            [SVProgressHUD dismiss];
            self.totalResults = [searchDetails[@"resultCount"] integerValue];
            self.pageCount = [searchDetails[@"pageCount"] integerValue];
            [self updateSearchResults:searchDetails[@"results"]];
            [self.tableView reloadData];
            
        } failureBlock:^(NSString *error) {
            [SVProgressHUD dismiss];
            
        }];
    } else if (type == 3) //sports
    {
        self.navigationItem.title = @"#Sports";
        [[KBYourTube sharedInstance] getChannelVideos:KBYTSportsChannelID completionBlock:^(NSDictionary *searchDetails) {
            
            self.currentPage = 1;
            [SVProgressHUD dismiss];
            self.totalResults = [searchDetails[@"resultCount"] integerValue];
            self.pageCount = [searchDetails[@"pageCount"] integerValue];
            [self updateSearchResults:searchDetails[@"results"]];
            [self.tableView reloadData];
            
        } failureBlock:^(NSString *error) {
            [SVProgressHUD dismiss];
            
        }];
    } else if (type == 4) //360
    {
         self.navigationItem.title = @"360 Videos";
        [[KBYourTube sharedInstance] getChannelVideos:KBYT360ChannelID completionBlock:^(NSDictionary *searchDetails) {
            
            self.currentPage = 1;
            [SVProgressHUD dismiss];
            self.totalResults = [searchDetails[@"resultCount"] integerValue];
            self.pageCount = [searchDetails[@"pageCount"] integerValue];
            [self updateSearchResults:searchDetails[@"results"]];
            [self.tableView reloadData];
            
        } failureBlock:^(NSString *error) {
            [SVProgressHUD dismiss];
            
        }];
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
    
    return self.searchResults.count;
    
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    tableView.backgroundColor = [UIColor whiteColor];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}
- (void)updateSearchResults:(NSArray *)newResults
{
    self.searchResults = [newResults mutableCopy];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    KBYTDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[KBYTDownloadCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.detailTextLabel.text = currentItem.author;
    cell.textLabel.text = currentItem.title;
    cell.duration = currentItem.duration;
    
    NSNumberFormatter *numFormatter = [NSNumberFormatter new];
    numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    NSNumber *view_count = [numFormatter numberFromString:currentItem.views];

    cell.views = [[numFormatter stringFromNumber:view_count] stringByAppendingString:@" Views"];
    cell.downloading = false;
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceHolderImage"];
    // UIImage *theImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"YTPlaceHolderImage" ofType:@"png"]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    cell.imageView.autoresizingMask = ( UIViewAutoresizingNone );
    [cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
      [[self tableView] deselectRowAtIndexPath:indexPath animated:false];
    if (indexPath.row >= self.searchResults.count)
    {
        return; //selected the spinner item, jerks.
    }
    KBYTSearchResult *currentResult = [self.searchResults objectAtIndex:indexPath.row];
    //[SVProgressHUD showInfoWithStatus:@"Fetching details"];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForID:currentResult.videoId completionBlock:^(KBYTMedia *videoDetails) {
        
        //
        [SVProgressHUD dismiss];
        KBYTSearchItemViewController *searchItem = [[KBYTSearchItemViewController alloc] initWithMedia:videoDetails];
        [[self navigationController] pushViewController:searchItem animated:true];
        
    } failureBlock:^(NSString *error) {
        [SVProgressHUD dismiss];
        
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



- (void)checkAirplay
{
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
    NSString *requestString = [NSString stringWithFormat:@"http://%@/scrub?position=%f", [[KBYourTube sharedInstance] airplayIP], position];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"POST"];
    //  NSLog(@"returnDict: %@", returnDict);
    return returnDict;
    
    //   /scrub?position=20.097000
}

- (NSDictionary *)getAirplayDetails
{
    NSString *requestString = [NSString stringWithFormat:@"http://%@/playback-info", [[KBYourTube sharedInstance] airplayIP]];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"GET"];
    //    NSLog(@"returnDict: %@", returnDict);
    return returnDict;
}



@end
