//
//  KBYTDownloadsTableViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 1/27/16.
//
//

#import "KBYTDownloadsTableViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "OurViewController.h"

@implementation KBYTDownloadCell

@synthesize downloading, progressView;

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    LOG_SELF;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(0,0,133,100);
    self.imageView.backgroundColor = [UIColor blackColor];
    float limgW =  self.imageView.image.size.width;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if(limgW > 0) {
        
        CGFloat textFieldWidth = self.frame.size.width - 148 - 10;
        if ([self marqueeTextLabel] != nil)
        {
            [[self marqueeTextLabel] removeFromSuperview];
        }
        if ([self marqueeDetailTextLabel] != nil)
        {
            [[self marqueeDetailTextLabel] removeFromSuperview];
        }
        self.textLabel.frame = CGRectMake(148 ,self.textLabel.frame.origin.y,textFieldWidth,self.textLabel.frame.size.height);
        self.marqueeTextLabel = [[MarqueeLabel alloc] initWithFrame:self.textLabel.frame];
        self.marqueeTextLabel.font = self.textLabel.font;
        self.marqueeTextLabel.textColor = self.textLabel.textColor;
        self.marqueeTextLabel.text = self.textLabel.text;
        self.textLabel.hidden = true;
        self.detailTextLabel.frame = CGRectMake(148,self.detailTextLabel.frame.origin.y,textFieldWidth,self.detailTextLabel.frame.size.height);
        self.marqueeDetailTextLabel = [[MarqueeLabel alloc] initWithFrame:self.detailTextLabel.frame];
        self.marqueeDetailTextLabel.font = self.detailTextLabel.font;
        self.marqueeDetailTextLabel.textColor = [UIColor lightGrayColor];//self.detailTextLabel.textColor;
        self.marqueeDetailTextLabel.text = self.detailTextLabel.text;
        [[self contentView] addSubview:self.marqueeDetailTextLabel];
        [[self contentView] addSubview:self.marqueeTextLabel];
        self.marqueeDetailTextLabel.frame =  self.detailTextLabel.frame;
        self.detailTextLabel.hidden = true;
        
        if ([self progressView] != nil)
        {
            [[self progressView] removeFromSuperview];
        }
        
        if (self.downloading == true)
        {
            self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(148, self.detailTextLabel.frame.origin.y + self.textLabel.frame.size.height + 5, textFieldWidth, 2)];
            [[self contentView] addSubview:self.progressView];
        }
    }
    
    
    
}

@end

@interface KBYTDownloadsTableViewController ()

@end

@implementation KBYTDownloadsTableViewController

@synthesize downloadArray, activeDownloads;

- (NSString *)downloadFile
{
    return @"/var/mobile/Library/Application Support/tuyu/Downloads.plist";
}

- (NSString *)downloadPath
{
    return @"/var/mobile/Library/Application Support/tuyu/Downloads";
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    NSArray *fullArray = [NSArray arrayWithContentsOfFile:[self downloadFile]];
    self.activeDownloads = [fullArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"inProgress == YES"]];
    self.downloadArray = [fullArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"inProgress == NO"]];
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
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Downloads";
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return name;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
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
    switch (indexPath.section) {
        case 0:
            currentItem = [self.activeDownloads objectAtIndex:indexPath.row];
            downloading = true;
            break;
            
        case 1:
            currentItem = [self.downloadArray objectAtIndex:indexPath.row];
            break;
            
    }
    // UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    cell.detailTextLabel.text = currentItem[@"author"];
    cell.textLabel.text = currentItem[@"title"];
    cell.downloading = downloading;
    NSURL *imageURL = [NSURL URLWithString:currentItem[@"images"][@"medium"]];
    UIImage *theImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GenericArtwork" ofType:@"png"]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    cell.imageView.autoresizingMask = ( UIViewAutoresizingNone );
    [cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    
    /*
     [cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates | SDWebImageAvoidAutoSetImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
     
     cell.imageView.image = [image scaledImagedToSize:CGSizeMake(133, 100)];
     
     }];
     */
    // Configure the cell...
    //cell.imageView = [UIImage imageWith]
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

- (void)deleteMedia:(NSDictionary *)dictionaryMedia
{
    NSString *filePath = [[self downloadPath] stringByAppendingPathComponent:dictionaryMedia[@"outputFilename"]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    NSMutableArray *mutableArray = [[self downloadArray] mutableCopy];
    [mutableArray removeObject:dictionaryMedia];
    [mutableArray writeToFile:[self downloadFile] atomically:true];
    self.downloadArray = mutableArray;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return NO;
    }
    
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        NSDictionary *mediaToDelete = [self.downloadArray objectAtIndex:indexPath.row];
        [tableView beginUpdates];
        [self deleteMedia:mediaToDelete];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
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
    if (indexPath.section == 1)
    {
        NSDictionary *theFile = [self.downloadArray objectAtIndex:indexPath.row];
        OurViewController *vc = self.navigationController.viewControllers.firstObject;
        [vc playFile:theFile];
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
