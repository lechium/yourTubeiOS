//
//  SettingsViewController.m
//
//  RZSplitViewController Created by Joe Goullaud on 8/6/12.

//  Renamed and modified by Kevin Bradley 3/10/16 to create an easier settings view controller for ATV4

// Copyright 2014 Raizlabs and other contributors
// http://raizlabs.com/
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <QuartzCore/QuartzCore.h>
#import "YTTVPlaylistViewController.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "TYAuthUserManager.h"

@implementation PlaylistTableViewCell

@synthesize viewBackgroundColor, selectionColor;

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.selectionColor == nil)
        self.selectionColor = [UIColor whiteColor];
    
    if (self.viewBackgroundColor == nil)
        self.viewBackgroundColor = self.contentView.backgroundColor;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    if (context.nextFocusedView == self)
    {
        [coordinator addCoordinatedAnimations:^{
            // self.backgroundColor = [UIColor darkGrayColor];
            CGRect tlf = self.textLabel.frame;
            tlf.origin.x += 40;
            tlf.origin.y += 30;
            self.textLabel.frame = tlf;
            self.marqueeTextLabel.frame = tlf;
            TLog(@"focused %@ self.textLabel.frame: %@", self.textLabel.text, NSStringFromCGRect(self.textLabel.frame));
            self.imageView.adjustsImageWhenAncestorFocused = true;
            self.contentView.backgroundColor = self.selectionColor;
            
            //NSLog(@"superview: %@",  self.superview.superview.superview.superview.superview.superview);
        } completion:^{
            //
        }];
        
    } else {
        [coordinator addCoordinatedAnimations:^{
            //self.backgroundColor = [UIColor blackColor];
            CGRect tlf = self.textLabel.frame;
            tlf.origin.x = 148;
            tlf.origin.y = -10;
            self.textLabel.frame = tlf;
            self.marqueeTextLabel.frame = tlf;
            TLog(@"unfocused %@ self.textLabel.frame: %@",self.textLabel.text, NSStringFromCGRect(self.textLabel.frame));
            self.imageView.adjustsImageWhenAncestorFocused = false;
            self.contentView.backgroundColor = self.viewBackgroundColor;
        } completion:^{
            //
        }];
    }
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    //self.marqueeTextLabel.holdScrolling = true;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end

@interface PLDetailViewController ()

@end

@implementation PLDetailViewController

@synthesize imageURLs;

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect selfFrame = [self.view frame];
    selfFrame.size.width = selfFrame.size.width / 2;
    CGSize imageSize = CGSizeMake(768, 768);
    CGRect imageRect = CGRectMake((selfFrame.size.width - imageSize.width)/2, (selfFrame.size.height - imageSize.height)/2, imageSize.width, imageSize.height);
    self.imageView = [[UIImageView alloc] initWithFrame:imageRect];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = [UIImage imageNamed:@"YTPlaceholder"];
    /*
     if (imageURLs.count > 0)
     {
     UIImage *theImage = [UIImage imageNamed:imageURLs[0]];
     [self.imageView setImage:theImage];
     }*/
    [[self view]addSubview:self.imageView];
    
}

- (void)addImageURLs:(NSArray *)urls {
    NSMutableArray *images = [[NSMutableArray alloc] initWithArray:self.imageURLs];
    [images addObjectsFromArray:urls];
    self.imageURLs = images;
}

- (void)selectedItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.imageURLs.count)
    {
        [self.imageView sd_setImageWithURL:self.imageURLs[indexPath.row] placeholderImage:[UIImage imageNamed:@"YTPlaceholder"] options:SDWebImageAllowInvalidSSLCertificates completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (error) {
                [self.imageView sd_setImageWithURL:imageURL.highResVideoURL placeholderImage:[UIImage imageNamed:@"YTPlaceholder"] options:SDWebImageAllowInvalidSSLCertificates];
            }
        }];
        //UIImage *theImage = [UIImage imageNamed:imageURLs[indexPath.row]];
        //[self.imageView setImage:theImage];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

@interface PlaylistTableViewController ()
@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;
@property (readwrite, assign) NSInteger currentPage;

@end

@implementation PlaylistTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentPage = 1;
    self.tableView.contentInset = UIEdgeInsetsMake(30, 0, 20, 0);
    //self.view.backgroundColor = [UIColor blackColor];
    [self.tableView registerClass:[PlaylistTableViewCell class] forCellReuseIdentifier:@"Science"];
    
    UILongPressGestureRecognizer *longpress
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongpressMethod:)];
    longpress.minimumPressDuration = .5; //seconds
    longpress.delegate = self;
    longpress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [self.tableView addGestureRecognizer:longpress];
    
    //self.tableView.maskView = nil;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (KBYTSearchResult *)searchResultFromFocusedCell {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    KBYTSearchResult *searchResult = [self.itemNames objectAtIndex:indexPath.row];
    return searchResult;
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

-(void) handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {
    LOG_SELF;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if (![[KBYourTube sharedInstance] isSignedIn]) {
        return;
    }
    
    KBYTSearchResult *searchResult = [self searchResultFromFocusedCell];
    
    NSLog(@"searchResult: %@", searchResult);
    
    switch (searchResult.resultType)
    {
        case kYTSearchResultTypeVideo:
            
            [self showPlaylistAlertForSearchResult:searchResult];
            break;
            
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)selectedItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(selectedItemAtIndexPath:)])
    {
        [self.delegate selectedItemAtIndexPath:indexPath];
    }
}

- (void)updateSearchResults:(NSArray *)newResults {
    if (self.currentPage > 1)
    {
        [[self itemNames] addObjectsFromArray:newResults];
    } else {
        self.itemNames = [newResults mutableCopy];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}


- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [self focusedCell:(PlaylistTableViewCell*)context.nextFocusedView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.itemNames.count;
}

- (void)focusedCell:(PlaylistTableViewCell *)focusedCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:focusedCell];
    [self.delegate selectedItemAtIndexPath:indexPath];
    if (indexPath.row == self.itemNames.count-1)
    {
        if (self.playlistItem.continuationToken.length > 0)
        {
            [self getNextPage];
        }
    }
}

- (void)getNextPage {
    LOG_SELF;
    self.currentPage++;
    [[KBYourTube sharedInstance] getPlaylistVideos:self.playlistItem.playlistID continuation:self.playlistItem.continuationToken completionBlock:^(KBYTPlaylist *playlist) {
        [self updateSearchResults:playlist.videos];
        self.playlistItem.continuationToken = playlist.continuationToken;
        NSMutableArray *imageArray = [NSMutableArray new];
        for (KBYTSearchResult *result in playlist.videos) {
            [imageArray addObject:result.imagePath];
        }
        [self.delegate addImageURLs:imageArray];
        [self.tableView reloadData];
    } failureBlock:^(NSString *error) {
        [self.tableView reloadData];
    }];
}

- (void)playAllSearchResults:(NSArray *)searchResults {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:@[[searchResults firstObject]] completionBlock:^(NSArray *videoArray) {
        
        [SVProgressHUD dismiss];
        self.playerView = [[YTKBPlayerViewController alloc] initWithFrame:self.view.frame usingStreamingMediaArray:searchResults];
        [self.playerView addObjectsToPlayerQueue:videoArray];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *subarray = [[self itemNames] subarrayWithRange:NSMakeRange(indexPath.row, [[self itemNames] count] - indexPath.row)];
    [self playAllSearchResults:subarray];
    if ([self.selectionDelegate respondsToSelector:@selector(itemSelectedAtIndexPath:)])
    {
        [self.selectionDelegate itemSelectedAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PlaylistTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Science"forIndexPath:indexPath];
    
    // Configure the cell...
    KBYTSearchResult *currentItem = self.itemNames[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = currentItem.title;
    cell.duration = currentItem.duration;
    cell.downloading = false;
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceHolderImage"];
    // UIImage *theImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"YTPlaceHolderImage" ofType:@"png"]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    cell.imageView.autoresizingMask = ( UIViewAutoresizingNone );
    [cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            //TLog(@"error: %@ url: %@, hr: %@", error, imageURL, [imageURL highResVideoURL]);
            [cell.imageView sd_setImageWithURL:[imageURL highResVideoURL] placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
        }
    }];
    //[cell.imageView sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    cell.viewBackgroundColor = self.view.backgroundColor;
    if (self.view.backgroundColor == [UIColor blackColor])
    {
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.marqueeTextLabel.textColor = [UIColor whiteColor];
        cell.selectionColor = [UIColor darkGrayColor];
    }
    
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

@end



#define kRZSplitViewMasterIndex 0
#define kRZSplitViewDetailIndex 1

@interface YTTVPlaylistViewController () <UINavigationControllerDelegate>

@property (strong, nonatomic, readwrite) UIBarButtonItem *collapseBarButton;
@property (nonatomic, assign) BOOL usingCustomMasterWidth;

- (void)initializeSplitViewController;

- (void)layoutViewControllers;
- (void)layoutViewsForCollapsed:(BOOL)collapsed animated:(BOOL)animated;

- (void)configureCollapseButton:(UIBarButtonItem*)collapseButton forCollapsed:(BOOL)collapsed;

- (void)collapseBarButtonTapped:(id)sender;

@end

//changed master width to default to half of the screen width
#define RZSPLITVIEWCONTROLLER_DEFAULT_MASTER_WIDTH 960.0f
#define RZSPLITVIEWCONTROLLER_DEFAULT_CORNER_RADIUS 4.0f
//got rid of the border
#define RZSPLITVIEWCONTROLLER_DEFAULT_BORDER_WIDTH 0.0f

@implementation YTTVPlaylistViewController
@synthesize viewControllers = _viewControllers;
@synthesize delegate = _delegate;
@synthesize collapseBarButtonImage = _collapseBarButtonImage;
@synthesize expandBarButtonImage = _expandBarButtonImage;
@synthesize collapseBarButton = _collapseBarButton;
@synthesize collapsed = _collapsed;
@synthesize viewBorderColor = _viewBorderColor;
@synthesize viewBorderWidth = _viewBorderWidth;
@synthesize viewCornerRadius = _viewCornerRadius;
@synthesize itemNames, imageNames;


+ (id)playlistViewControllerForPlaylist:(KBYTPlaylist *)playlist backgroundColor:(UIColor* )bgColor {
    YTTVPlaylistViewController *splitViewController = [YTTVPlaylistViewController new];
    splitViewController.view.backgroundColor = bgColor;
    //splitViewController.itemNames = names;
    //splitViewController.imageNames = images;
    splitViewController.view.backgroundColor = bgColor;
    PlaylistTableViewController *masterTableViewController = [[PlaylistTableViewController alloc] init];
    masterTableViewController.playlistItem = playlist;
    masterTableViewController.itemNames = [[NSMutableArray alloc] initWithArray:playlist.videos];
    
    masterTableViewController.selectionDelegate = splitViewController;
    PLDetailViewController *detailViewController = [[PLDetailViewController alloc] init];
    detailViewController.view.backgroundColor = bgColor;
    NSMutableArray *imageArray = [NSMutableArray new];
    for (KBYTSearchResult *result in playlist.videos)
    {
        [imageArray addObject:result.imagePath];
    }
    detailViewController.imageURLs = imageArray;
    masterTableViewController.view.backgroundColor = bgColor;
    masterTableViewController.delegate = detailViewController;
    [splitViewController setViewControllers:@[detailViewController,masterTableViewController]];
    splitViewController.title = playlist.title;
    [splitViewController setTitle:playlist.title];
    return splitViewController;
}

+ (id)playlistViewControllerWithTitle:(NSString *)theTitle backgroundColor:(UIColor *)bgColor withPlaylistItems:(NSArray *)playlistItems {
    YTTVPlaylistViewController *splitViewController = [YTTVPlaylistViewController new];
    splitViewController.view.backgroundColor = bgColor;
    //splitViewController.itemNames = names;
    //splitViewController.imageNames = images;
    splitViewController.view.backgroundColor = bgColor;
    PlaylistTableViewController *masterTableViewController = [[PlaylistTableViewController alloc] init];
    masterTableViewController.itemNames = [[NSMutableArray alloc] initWithArray:playlistItems];
    
    masterTableViewController.selectionDelegate = splitViewController;
    PLDetailViewController *detailViewController = [[PLDetailViewController alloc] init];
    detailViewController.view.backgroundColor = bgColor;
    NSMutableArray *imageArray = [NSMutableArray new];
    for (KBYTSearchResult *result in playlistItems)
    {
        [imageArray addObject:result.imagePath];
    }
    detailViewController.imageURLs = imageArray;
    masterTableViewController.view.backgroundColor = bgColor;
    masterTableViewController.delegate = detailViewController;
    [splitViewController setViewControllers:@[detailViewController,masterTableViewController]];
    splitViewController.title = theTitle;
    [splitViewController setTitle:theTitle];
    return splitViewController;
}


- (void)itemSelectedAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.selectionDelegate respondsToSelector:@selector(itemSelectedAtIndexPath:fromNavigationController:)]) {
        [self.selectionDelegate itemSelectedAtIndexPath:indexPath fromNavigationController:self.navigationController];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.usingCustomMasterWidth = NO;
        [self initializeSplitViewController];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initializeSplitViewController];
}

- (void)setMasterWidth:(CGFloat)masterWidth {
    self.usingCustomMasterWidth = YES;
    _masterWidth = masterWidth;
}

- (void)initializeSplitViewController {
    self.viewCornerRadius = RZSPLITVIEWCONTROLLER_DEFAULT_CORNER_RADIUS;
    self.viewBorderWidth = RZSPLITVIEWCONTROLLER_DEFAULT_BORDER_WIDTH;
    self.viewBorderColor = self.view.backgroundColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.view.backgroundColor = [UIColor blackColor];
    [self layoutViewControllers];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self layoutViewsForCollapsed:self.collapsed animated:NO];
    //NSLog(@"masterViewContorller: %@", self.detailViewController);
    PlaylistTableViewController *plTvC = (PlaylistTableViewController *)self.detailViewController;
    plTvC.nextHREF = self.loadMoreHREF;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Property Accessor Overrides

- (UIViewController*)masterViewController {
    return [self.viewControllers objectAtIndex:kRZSplitViewMasterIndex];
}

- (UIViewController*)detailViewController {
    return [self.viewControllers objectAtIndex:kRZSplitViewDetailIndex];
}

- (void)setViewControllers:(NSArray *)viewControllers {
    NSAssert(2 == [viewControllers count], @"You must have exactly 2 view controllers in the array. This array has %lu.", (long)[viewControllers count]);
    
    [_viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *vc = (UIViewController*)obj;
        
        [vc willMoveToParentViewController:nil];
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
    }];
    
    _viewControllers = [viewControllers copy];
    
    [_viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *vc = (UIViewController*)obj;
        
        [self addChildViewController:vc];
        [vc didMoveToParentViewController:self];
    }];
    
    [self layoutViewControllers];
}

- (void)setCollapseBarButtonImage:(UIImage *)collapseBarButtonImage {
    _collapseBarButtonImage = collapseBarButtonImage;
    
    if (!self.collapsed)
    {
        [_collapseBarButton setImage:_collapseBarButtonImage];
    }
}

- (void)setExpandBarButtonImage:(UIImage *)expandBarButtonImage {
    _expandBarButtonImage = expandBarButtonImage;
    
    if (self.collapsed)
    {
        [_collapseBarButton setImage:_expandBarButtonImage];
    }
}

- (void)setDetailViewController:(UIViewController*)detailVC {
    NSAssert(detailVC != nil, @"The detail view controller must not be nil");
    
    if (detailVC)
    {
        NSMutableArray* updatedViewControllers = [[self viewControllers] mutableCopy];
        [updatedViewControllers setObject:detailVC atIndexedSubscript:kRZSplitViewDetailIndex];
        [self setViewControllers:updatedViewControllers];
    }
}

- (void)setMasterViewController:(UIViewController*)masterVC {
    NSAssert(masterVC != nil, @"The master view controller must not be nil");
    
    if (masterVC)
    {
        NSMutableArray* updatedViewControllers = [[self viewControllers] mutableCopy];
        [updatedViewControllers setObject:masterVC atIndexedSubscript:kRZSplitViewMasterIndex];
        [self setViewControllers:updatedViewControllers];
    }
}

- (UIBarButtonItem*)collapseBarButton {
    if (nil == _collapseBarButton)
    {
        _collapseBarButton = [[UIBarButtonItem alloc] initWithTitle:(self.collapsed ? @">>" : @"<<") style:UIBarButtonItemStylePlain target:self action:@selector(collapseBarButtonTapped:)];
        
        [self configureCollapseButton:_collapseBarButton forCollapsed:self.collapsed];
    }
    
    return _collapseBarButton;
}

- (void)setCollapsed:(BOOL)collapsed {
    [self setCollapsed:collapsed animated:NO];
}

- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated {
    if (collapsed == _collapsed)
    {
        return;
    }
    
    _collapsed = collapsed;
    
    [self layoutViewsForCollapsed:collapsed animated:animated];
}

#pragma mark - Private Property Accessor Overrides

#pragma mark - View Controller Layout

- (void)layoutViewControllers {
    UIViewController *masterVC = [self.viewControllers objectAtIndex:kRZSplitViewMasterIndex];
    UIViewController *detailVC = [self.viewControllers objectAtIndex:kRZSplitViewDetailIndex];
    
    UIViewAutoresizing masterAutoResizing = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    UIViewAutoresizing detailAutoResizing = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    masterVC.view.contentMode = UIViewContentModeScaleToFill;
    masterVC.view.autoresizingMask = masterAutoResizing;
    masterVC.view.autoresizesSubviews = YES;
    //masterVC.view.clipsToBounds = YES;
    
    masterVC.view.layer.borderWidth = self.viewBorderWidth;
    masterVC.view.layer.borderColor = [self.viewBorderColor CGColor];
    masterVC.view.layer.cornerRadius = self.viewCornerRadius;
    
    detailVC.view.contentMode = UIViewContentModeScaleToFill;
    detailVC.view.autoresizingMask = detailAutoResizing;
    detailVC.view.autoresizesSubviews = YES;
    //detailVC.view.clipsToBounds = YES;
    
    detailVC.view.layer.borderWidth = self.viewBorderWidth;
    detailVC.view.layer.borderColor = [self.viewBorderColor CGColor];
    detailVC.view.layer.cornerRadius = self.viewCornerRadius;
    
    [self.view addSubview:masterVC.view];
    [self.view addSubview:detailVC.view];
    
    [self layoutViewsForCollapsed:self.collapsed animated:NO];
}

- (void)layoutViewsForCollapsed:(BOOL)collapsed animated:(BOOL)animated {
    void (^layoutBlock)(void);
    void (^completionBlock)(BOOL finished);
    
    UIViewController *masterVC = [self.viewControllers objectAtIndex:0];
    UIViewController *detailVC = [self.viewControllers objectAtIndex:1];
    
    CGRect viewBounds = self.view.bounds;
    CGFloat masterWidth = self.usingCustomMasterWidth ? self.masterWidth : RZSPLITVIEWCONTROLLER_DEFAULT_MASTER_WIDTH;
    
    if (collapsed)
    {
        layoutBlock = ^(void){
            CGRect masterFrame = CGRectMake(-masterWidth, 0, masterWidth+1.0, viewBounds.size.height);
            CGRect detailFrame = CGRectMake(0, 0, viewBounds.size.width, viewBounds.size.height);
            
            masterVC.view.frame = masterFrame;
            detailVC.view.frame = detailFrame;
        };
        
        completionBlock = ^(BOOL finished){
            [masterVC.view removeFromSuperview];
        };
    }
    else
    {
        if (masterVC.view.superview != self.view)
        {
            [self.view addSubview:masterVC.view];
        }
        masterVC.view.frame = CGRectMake(-RZSPLITVIEWCONTROLLER_DEFAULT_MASTER_WIDTH, 0, RZSPLITVIEWCONTROLLER_DEFAULT_MASTER_WIDTH+1.0, viewBounds.size.height);
        
        
        masterVC.view.frame = CGRectMake(-masterWidth, 0, masterWidth+1.0, viewBounds.size.height);
        
        
        layoutBlock = ^(void){
            CGRect masterFrame = CGRectMake(0, 0, masterWidth+1.0, viewBounds.size.height);
            
            //made some changes here because the table view was too high, too wide and getting cut off.
            CGRect detailFrame = CGRectMake(masterWidth+30, 180, viewBounds.size.width - (masterWidth )-80, viewBounds.size.height - 180);
            
            masterVC.view.frame = masterFrame;
            detailVC.view.frame = detailFrame;
        };
        
        completionBlock = ^(BOOL finished){
            
        };
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionLayoutSubviews
                         animations:layoutBlock
                         completion:completionBlock];
    }
    else
    {
        layoutBlock();
        completionBlock(YES);
    }
}

- (void)configureCollapseButton:(UIBarButtonItem*)collapseButton forCollapsed:(BOOL)collapsed {
    if (collapsed)
    {
        if (self.expandBarButtonImage)
        {
            [collapseButton setImage:self.expandBarButtonImage];
        }
        else if (self.collapseBarButtonImage)
        {
            [collapseButton setImage:self.collapseBarButtonImage];
        }
        else
        {
            [collapseButton setTitle:@">>"];
        }
    }
    else
    {
        if (self.collapseBarButtonImage)
        {
            [collapseButton setImage:self.collapseBarButtonImage];
        }
        else
        {
            [collapseButton setTitle:@"<<"];
        }
    }
}

#pragma mark - Action Methods

- (void)collapseBarButtonTapped:(id)sender {
    BOOL collapsed = !self.collapsed;
    
    UIBarButtonItem *buttonItem = (UIBarButtonItem*)sender;
    
    [self configureCollapseButton:buttonItem forCollapsed:collapsed];
    
    [self setCollapsed:collapsed animated:YES];
}

@end

