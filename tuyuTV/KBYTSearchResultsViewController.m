//
//  KBYTSearchResultsViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/7/16.
//
//

#import "KBYTSearchResultsViewController.h"
#import "YTTVStandardCollectionViewCell.h"
#import "SVProgressHUD.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"

@interface KBYTSearchResultsViewController ()

@property (readwrite, assign) NSInteger currentPage;
@property (nonatomic, strong) NSString *filterString;
@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;

@end

@implementation KBYTSearchResultsViewController

@synthesize pageCount, currentPage, filterString;

static NSString * const reuseIdentifier = @"NewStandardCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
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

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

 
    return self.searchResults.count;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    LOG_SELF;
}
/*
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    LOG_SELF;
     KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    YTTVStandardCollectionViewCell *theCell = (YTTVStandardCollectionViewCell *)cell;
    NSLog(@"cell: %@", theCell);
    NSLog(@"title: %@", theCell.title.text);
    
    theCell.title.text = [NSString stringWithFormat:@"%@ - %@", currentItem.author, currentItem.title];
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
    [theCell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    NSLog(@"title: %@", theCell.title.text);
    
    
}
 
 */


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YTTVStandardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    
     NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
    [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    cell.title.text = [NSString stringWithFormat:@"%@ - %@", currentItem.author, currentItem.title];
    // Configure the cell
    
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

- (void)itemDidFinishPlaying:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
    [self dismissViewControllerAnimated:true completion:nil];
}


- (void)playFirstStreamForResult:(KBYTSearchResult *)searchResult
{
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForID:searchResult.videoId completionBlock:^(KBYTMedia *videoDetails) {
        
        [SVProgressHUD dismiss];
        NSURL *playURL = [[videoDetails.streams firstObject] url];
        AVPlayerViewController *playerView = [[AVPlayerViewController alloc] init];
        AVPlayerItem *singleItem = [AVPlayerItem playerItemWithURL:playURL];
        
        playerView.player = [AVQueuePlayer playerWithPlayerItem:singleItem];
        [self presentViewController:playerView animated:YES completion:nil];
        [playerView.player play];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:singleItem];
        
        
    } failureBlock:^(NSString *error) {
        
    }];
    
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{

    self.filterString = searchController.searchBar.text;
    if (self.currentPage == 1)
        [SVProgressHUD show];
    [[KBYourTube sharedInstance] youTubeSearch:self.filterString pageNumber:self.currentPage includeAllResults:false completionBlock:^(NSDictionary *searchDetails) {
        
        //  NSLog(@"search details: %@", searchDetails);
        if (self.currentPage == 1)
            [SVProgressHUD dismiss];
        
        self.totalResults = [searchDetails[@"resultCount"] integerValue];
        self.pageCount = [searchDetails[@"pageCount"] integerValue];
        //self.searchResults = searchDetails[@"results"];
        [self updateSearchResults:searchDetails[@"results"]];
        [self.collectionView reloadData];
        
        
    } failureBlock:^(NSString *error) {
        //
        [SVProgressHUD dismiss];
        
    }];
}

#pragma mark <UICollectionViewDelegate>


// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}



// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    KBYTSearchResult *searchResult = [self.searchResults objectAtIndex:indexPath.row];
    [self playFirstStreamForResult:searchResult];
}

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
