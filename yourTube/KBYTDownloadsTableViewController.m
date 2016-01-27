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
    }
   
}

@end

@interface KBYTDownloadsTableViewController ()

@end

@implementation KBYTDownloadsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
     self.downloadArray= [NSArray arrayWithContentsOfFile:@"/var/mobile/Library/Application Support/tuyu/Downloads.plist"];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
   self.navigationItem.title = @"Downloads";
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
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
    
    NSDictionary *currentItem = [self.downloadArray objectAtIndex:indexPath.row];
    // UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    cell.detailTextLabel.text = currentItem[@"author"];
    cell.textLabel.text = currentItem[@"title"];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *theFile = [self.downloadArray objectAtIndex:indexPath.row];
    OurViewController *vc = self.navigationController.viewControllers.firstObject;
    [vc playFile:theFile];
    
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
