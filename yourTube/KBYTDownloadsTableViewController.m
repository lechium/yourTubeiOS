//
//  KBYTDownloadsTableViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 1/27/16.
//
//

#import "KBYTDownloadsTableViewController.h"
#import "OurViewController.h"
#import "KBYTSearchTableViewController.h"
#import "Animations/ScaleAnimation.h"



@interface KBYTDownloadsTableViewController ()
{
    ScaleAnimation *_scaleAnimationController;
}
@end

@implementation KBYTDownloadsTableViewController

@synthesize downloadArray, activeDownloads, optionIndices;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    NSArray *fullArray = [NSArray arrayWithContentsOfFile:[self downloadFile]];
    self.activeDownloads = [fullArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"inProgress == YES"]];
    self.downloadArray = [fullArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"inProgress == NO"]];
    self.navigationController.view.backgroundColor = [UIColor redColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    return self;
}

- (void)delayedReloadData
{
    [self performSelector:@selector(reloadData) withObject:nil afterDelay:3];
}

- (void)reloadData {
    LOG_SELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *fullArray = [NSArray arrayWithContentsOfFile:[self downloadFile]];
        self.activeDownloads = [fullArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"inProgress == YES"]];
        self.downloadArray = [fullArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"inProgress == NO"]];
        [[self tableView] reloadData];
    });
    
}

- (void)updateDownloadProgress:(NSDictionary *)theDict
{
    NSString *title = [theDict[@"file"] lastPathComponent];
    NSDictionary *theObject = [[self.activeDownloads filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.outputFilename == %@", title]]lastObject];
    if (theObject != nil)
    {
        
        
        NSInteger index = [self.activeDownloads indexOfObject:theObject];
        if (index != NSNotFound)
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
            KBYTDownloadCell *cell = [[self tableView] cellForRowAtIndexPath:path];
            [cell.progressView setProgress:[theDict[@"completionPercent"] floatValue]];
            if ([theDict[@"completionPercent"] integerValue] == 1)
            {
                [cell.progressView setIndeterminate:true];
            }
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.title = @"";
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationItem.title = @"Downloads";
    [super viewWillAppear:animated];
    [self reloadData];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Downloads";
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchView:)];
     _scaleAnimationController = [[ScaleAnimation alloc] initWithNavigationController:self.navigationController];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"burger"] style:UIBarButtonItemStylePlain target:self action:@selector(showHamburgerMenu)];

}

- (void)showHamburgerMenu
{
    NSArray *images = @[
                        [UIImage imageNamed:@"profile"],
                        [UIImage imageNamed:@"popular"],
                        [UIImage imageNamed:@"music"],
                        [UIImage imageNamed:@"sports"],
                        [UIImage imageNamed:@"360"],
                        [UIImage imageNamed:@"globe"]];
    
    
    NSArray *colors = @[
                        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1],
                        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1],
                        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1],
                        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1],
                        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1],
                        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1],
                        ];
    
    
    RNFrostedSidebar *callout = [[RNFrostedSidebar alloc] initWithImages:images selectedIndices:self.optionIndices borderColors:colors];
    
    
    callout.delegate = self;
    [callout show];
}


- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index {
    
    [sidebar dismissAnimated:YES completion:^(BOOL finished) {
        if (finished) {
            if (![Reachability checkInternetConnectionWithAlert])
            {
                return;
            }
            if (index == 5) //OG web search
            {
                OurViewController *ovc = [[OurViewController alloc] init];
                [self.navigationController pushViewController:ovc animated:true];
                return;
            }
            
            KBYTGenericVideoTableViewController *secondVC = [[KBYTGenericVideoTableViewController alloc]initForType:index];
            [self.navigationController pushViewController:secondVC animated:YES];
        }
    }];
}


- (void)showSearchView:(id)sender
{
    if (![Reachability checkInternetConnectionWithAlert])
    {
        return;
    }
    KBYTSearchTableViewController *searchView = [[KBYTSearchTableViewController alloc] init];
    _scaleAnimationController.viewForInteraction = searchView.view;
    
    [self.navigationController pushViewController:searchView animated:true];
    //[self presentViewController:searchView animated:true completion:^{
    
    //
    // }];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *name = nil;
    
    switch (section) {
        case 0: //
            
            name = @"Active Downloads";
            break;
            
        case 1: //
            
            name = @"Downloads";
            break;
            
    }
    
    if (self.activeDownloads.count == 0)
    {
        name = @"Downloads";
    }
    return name;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if ([[self activeDownloads] count] > 0)
    {
        return 2;

    }
    return 1; //no active downloads
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([[self activeDownloads] count] == 0)
    {
        return [[self downloadArray] count];
    }
    switch (section) {
        case 0:
            
            return [[self activeDownloads] count];
            
        case 1:
            
            return [[self downloadArray] count];
            
            
    }
    return [self.downloadArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    KBYTDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[KBYTDownloadCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *currentItem = nil;
    BOOL downloading = false;
    
    if ([[self activeDownloads] count] == 0)
    {
        currentItem = [self.downloadArray objectAtIndex:indexPath.row];
        downloading = false;
    } else {
        
        switch (indexPath.section) {
            case 0:
                currentItem = [self.activeDownloads objectAtIndex:indexPath.row];
                downloading = true;
                break;
                
            case 1:
                currentItem = [self.downloadArray objectAtIndex:indexPath.row];
                break;
        }
    }
   // NSString *duration = [NSString stringFromTimeInterval:[currentItem[@"duration"]integerValue]];
    cell.duration = [NSString stringFromTimeInterval:[currentItem[@"duration"]integerValue]];
    cell.detailTextLabel.text = currentItem[@"author"];
    cell.textLabel.text = currentItem[@"title"];
    if ([[currentItem allKeys] containsObject:@"format"] && downloading == false)
    {
        //cell.views = [currentItem[@"views"] stringByAppendingString:@" Views"];
        cell.views = currentItem[@"format"];
    }
    
    if (downloading == true)
    {
        cell.views = @"";
    }
    cell.downloading = downloading;
    NSURL *imageURL = [NSURL URLWithString:currentItem[@"images"][@"medium"]];
    UIImage *theImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GenericArtwork" ofType:@"png"]];
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

- (void)deleteMedia:(NSDictionary *)dictionaryMedia fromSection:(NSInteger)section
{
    if (section == 0) //active download, no file to delete
    {
        [[KBYTMessagingCenter sharedInstance] stopDownload:dictionaryMedia];
        NSMutableArray *mutableArray = [[self activeDownloads] mutableCopy];
        [mutableArray removeObject:dictionaryMedia];
        self.activeDownloads = mutableArray;
        //NSMutableArray *mutableArray = [[self downloadArray] mutableCopy];
        
        
    } else {
        
        
        NSString *filePath = [[self downloadFolder] stringByAppendingPathComponent:dictionaryMedia[@"outputFilename"]];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        NSMutableArray *mutableArray = [[self downloadArray] mutableCopy];
        [mutableArray removeObject:dictionaryMedia];
        self.downloadArray = [mutableArray copy]; //this needs to be a copy otherwise when we add the item
        //below top make sure the download plist file stays current the items being added during
        //download throw off the size of the table section arrays and it leads to a crash
        
        if ([self.activeDownloads count] > 0)
        {
            [mutableArray addObjectsFromArray:self.activeDownloads];
        }
        [mutableArray writeToFile:[self downloadFile] atomically:true];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if (indexPath.section == 0)
//    {
//        return NO;
//    }
//    
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        NSDictionary *mediaToDelete = nil;
        NSInteger section = indexPath.section;
      
        BOOL shouldRemoveActiveSection = false;
        
        if (self.activeDownloads.count == 0)
        {
            mediaToDelete = [self.downloadArray objectAtIndex:indexPath.row];
            section = 1;
        } else //if (self.activeDownloads.count == 1)
        {
          //  shouldRemoveActiveSection = true;
            switch (indexPath.section) {
                    
                case 0://active dl
                    if (self.activeDownloads.count == 1)
                    {
                        shouldRemoveActiveSection = true;
                    }
                    mediaToDelete = [self.activeDownloads objectAtIndex:indexPath.row];
                    break;
                    
                case 1: //finished dl
                    mediaToDelete = [self.downloadArray objectAtIndex:indexPath.row];
                    break;
                    
            }
        }
        
        [tableView beginUpdates];
        [self deleteMedia:mediaToDelete fromSection:section];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if (shouldRemoveActiveSection == true){
            [tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
        }
        [tableView endUpdates];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
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

-(void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player];
    [self dismissViewControllerAnimated:true completion:nil];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
}


- (void)playFile:(NSDictionary *)file
{
    NSString *outputFile = [[self downloadFolder] stringByAppendingPathComponent:file[@"outputFilename"]];
    /*
    NSURL *artworkURL = [NSURL URLWithString:file[@"images"][@"standard"]];
    NSData *albumArtwork = [NSData dataWithContentsOfURL:artworkURL];
    UIImage *artworkImage = [UIImage imageWithData:albumArtwork];
    NSLog(@"artworkImage: %@", artworkImage);
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc]initWithImage:artworkImage];
    NSLog(@"artwork: %@", artwork);
     */
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : file[@"title"], MPMediaItemPropertyPlaybackDuration: file[@"duration"] };//, MPMediaItemPropertyArtwork: artwork };
    
    NSURL *playURL = [NSURL fileURLWithPath:outputFile];
    NSLog(@"play url: %@", playURL);
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
      [[self tableView] deselectRowAtIndexPath:indexPath animated:false];
    if (self.activeDownloads.count == 0) { //first section is removed, this is still a bit of a hack but will work.
        
        NSDictionary *theFile = [self.downloadArray objectAtIndex:indexPath.row];
        [self playFile:theFile];
    
    } else { //we have active downloads so we need to make sure its section 1
        
        if (indexPath.section == 1)
        {
            NSDictionary *theFile = [self.downloadArray objectAtIndex:indexPath.row];
            [self playFile:theFile];
        }
    }
  
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
