
#import "KBYTSearchItemViewController.h"
#import <MediaPlayer/MediaPlayer.h>



float calcLabelHeight(NSString *string, UIFont *font, float width) {
	float height = [string sizeWithFont:font constrainedToSize:CGSizeMake(width, 1000.0f) lineBreakMode:UILineBreakModeTailTruncation].height + 16.0f;
	if (height > 32.0f)
		return height;
	return 32.0f;
}

@implementation KBYTSearchItemViewController


#pragma mark -
#pragma mark Initialization

@synthesize ytMedia;

- (id)initWithMedia:(KBYTMedia *)media
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        NSArray *airplayDevices = [[[KBYourTube sharedInstance] deviceController] airplayServers];
        //NSLog(@"airplayDevices: %@", airplayDevices);
        NSMutableArray *airplays = [NSMutableArray new];
        NSMutableArray *aircontrols = [NSMutableArray new];
        for (NSNetService *service in airplayDevices)
        {
            if ([[service type] isEqualToString:@"_aircontrol._tcp."])
            {
                [aircontrols addObject:[service name]];
                
            } else {
                [airplays addObject:[service name]];
            }
        }
        airplayServers = airplays;
        aircontrolServers = aircontrols;
        self.title = media.title;
        ytMedia = media;
        //NSLog(@"ytmedia: %@", ytMedia);
    }
    return self;
}


/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/


- (void)viewWillAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	/*
	UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
	rightBarButtonItem.style = UIBarButtonItemStyleBordered;
	self.navigationItem.rightBarButtonItem = rightBarButtonItem;
     */
}

- (void)close {
	[self dismissModalViewControllerAnimated:YES];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait || (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
    //return 3;
    NSInteger sections = 3;
    
    if ([aircontrolServers count] > 0)
        sections++;
    
    if ([airplayServers count] > 0)
        sections++;
    
    return sections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case 0:
			return 4;
		case 1:
			return ([ytMedia.streams count] > 0) ? [ytMedia.streams count] : 1;
		case 2:
			return ([ytMedia.streams count] > 0) ? [ytMedia.streams count] : 1;
        case 3:
            return ([airplayServers count] > 0) ? [airplayServers count] : 1;
        case 4:
            return ([aircontrolServers count] > 0) ? [aircontrolServers count] : 1;
    
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 1:
			return @"Stream";
			break;
		case 2:
			return @"Download";
			break;
        case 3:
            return @"Airplay";
        case 4:
            return @"Aircontrol";
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	float width = [UIScreen mainScreen].applicationFrame.size.width - 20.0f - ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 90.0f : 20.0f);
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					return calcLabelHeight(ytMedia.title, [UIFont fontWithName:@"Helvetica-Bold" size:13.0f], width);
					break;
				case 1:
					return calcLabelHeight(ytMedia.details, [UIFont fontWithName:@"Helvetica" size:13.0f], width);
					break;
				case 2:
					return calcLabelHeight([@"Views: " stringByAppendingString:ytMedia.views], [UIFont fontWithName:@"Helvetica" size:13.0f], width);
					break;
				case 3:
					return calcLabelHeight([@"Tags: " stringByAppendingString:ytMedia.keywords], [UIFont fontWithName:@"Helvetica" size:13.0f], width);
					break;
			}
			break;
	}
	return 44.0f;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = nil;
    KBYTStream *stream = nil;
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
					cell.textLabel.text = ytMedia.title;
					cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:13.0f];
					cell.textLabel.numberOfLines = 0;
					cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					return cell;
					break;
				case 1:
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
					if ([ytMedia.details isEqualToString:@""])
						cell.textLabel.text = @"(No Description)";
					else
						cell.textLabel.text = ytMedia.details;
					cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13.0f];
					cell.textLabel.numberOfLines = 0;
					cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					return cell;
					break;
				case 2:
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
					cell.textLabel.text = [@"Views: " stringByAppendingString:ytMedia.views];
					cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13.0f];
					cell.textLabel.numberOfLines = 0;
					cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					return cell;
					break;

				case 3:
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
				
                    cell.textLabel.text = [@"Tags: " stringByAppendingString:ytMedia.keywords];
					cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13.0f];
					cell.textLabel.numberOfLines = 0;
					cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					return cell;
					break;
			}
			break;
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil){
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            stream = [ytMedia.streams objectAtIndex:indexPath.row];
            cell.textLabel.text = stream.format;
            
			return cell;
			break;
            
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil)
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.textAlignment = UITextAlignmentCenter;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                stream = [ytMedia.streams objectAtIndex:indexPath.row];
                cell.textLabel.text = stream.format;
            
			return cell;
			break;
            
        case 3:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
           // stream = [ytMedia.streams objectAtIndex:indexPath.row];
            cell.textLabel.text = [airplayServers objectAtIndex:indexPath.row];
            
            return cell;
            
        case 4:
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            // stream = [ytMedia.streams objectAtIndex:indexPath.row];
            cell.textLabel.text = [aircontrolServers objectAtIndex:indexPath.row];
            
            return cell;
	}
    
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
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
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
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


#pragma mark -
#pragma mark Table view delegate


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

- (IBAction)playStream:(KBYTStream *)stream
{
    LOG_SELF;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    KBYTStream *currentStream = nil;
    self.airplayIP = nil;
    NSString *airdeviceName = nil;
    
    switch (indexPath.section) {
		case 1:
            currentStream = ytMedia.streams[indexPath.row];;
            [self playStream:currentStream];
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
		case 2:
            currentStream = ytMedia.streams[indexPath.row];
            [self downloadStream:currentStream];
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
            
        case 3:
            currentStream = ytMedia.streams[0];
            airdeviceName = airplayServers[indexPath.row];
           self.airplayIP = [[[KBYourTube sharedInstance] deviceController] deviceIPFromName:airdeviceName andType:0];
            [[KBYourTube sharedInstance] setAirplayIP:self.airplayIP];
            [[KBYourTube sharedInstance] airplayStream:currentStream ToDeviceIP:self.airplayIP ];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
            
        case 4:
            currentStream = ytMedia.streams[0];
            airdeviceName = aircontrolServers[indexPath.row];
           self.airplayIP =  [[[KBYourTube sharedInstance] deviceController] deviceIPFromName:airdeviceName andType:1];
            [[KBYourTube sharedInstance] setAirplayIP:self.airplayIP];
            [[KBYourTube sharedInstance] playMedia:self.ytMedia ToDeviceIP:self.airplayIP];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
	}
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
    streamDict[@"duration"] = self.ytMedia.duration;
    streamDict[@"author"] = self.ytMedia.author;
    streamDict[@"images"] = self.ytMedia.images;
    streamDict[@"inProgress"] = [NSNumber numberWithBool:true];
    streamDict[@"videoId"] = self.ytMedia.videoId;
    NSString *stringURL = [[stream url] absoluteString];
    streamDict[@"url"] = stringURL;
    [self updateDownloadsDictionary:streamDict];
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.importscience"];
    [center sendMessageName:@"org.nito.importscience.addDownload" userInfo:streamDict];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
}


@end

