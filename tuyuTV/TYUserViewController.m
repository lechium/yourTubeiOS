//
//  TYUserViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/7/16.
//
//

#import "TYUserViewController.h"
#import "YTTVStandardCollectionViewCell.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "YTKBPlayerViewController.h"
#import "KBYTQueuePlayer.h"
#import "MarqueeLabel.h"
#import "CollectionViewLayout.h"
#import "YTTVFeaturedCollectionViewCell.h"

@interface TYPlaylistCollectionHeaderView : UICollectionReusableView
{
    
}
@property (strong, nonatomic) UILabel *title;

@end

@implementation TYPlaylistCollectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.title = [[UILabel alloc] initWithFrame:CGRectMake(40, 50, 400, 40)];
        self.title.textColor = [UIColor whiteColor];
        self.title.font = [UIFont systemFontOfSize:40];
        [self addSubview:self.title];
    }
    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end


@interface TYUserViewController ()

@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;


@end

static NSString * const featuredReuseIdentifier = @"FeaturedCell";
static NSString * const standardReuseIdentifier = @"StandardCell";

@implementation TYUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupViews];
   // [self fetchUserDetails];
    [self fetchUserDetailsWithCompletionBlock:^(NSDictionary *finishedDetails) {
        
        self.playlistDictionary = finishedDetails;
        [[self playlistVideosCollectionView] reloadData];
    }];
    // Do any additional setup after loading the view.
}

- (void)setupViews
{
    CollectionViewLayout *layout = [CollectionViewLayout new];
    layout.minimumInteritemSpacing = 50;
    layout.minimumLineSpacing = 50;
    layout.itemSize = CGSizeMake(640, 480);
    layout.sectionInset = UIEdgeInsetsMake(-5, 50, 0, 50);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //layout.sectionInset = UIEdgeInsetsZero;
    self.channelVideosCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.channelVideosCollectionView.translatesAutoresizingMaskIntoConstraints = false;
    [self.channelVideosCollectionView registerNib:[UINib nibWithNibName:@"YTTVFeaturedCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:featuredReuseIdentifier];
    
    [self.channelVideosCollectionView registerClass:[TYPlaylistCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.channelVideosCollectionView setDelegate:self];
    [self.channelVideosCollectionView setDataSource:self];
    
    [self.view addSubview:self.channelVideosCollectionView];
    
    CollectionViewLayout *layoutTwo = [CollectionViewLayout new];
    
    layoutTwo.scrollDirection = UICollectionViewScrollDirectionVertical;
    layoutTwo.minimumInteritemSpacing = 10;
    layoutTwo.minimumLineSpacing = 50;
    layoutTwo.itemSize = CGSizeMake(320, 340);
    layoutTwo.sectionInset = UIEdgeInsetsMake(35, 50, 20, 50);
    layoutTwo.headerReferenceSize = CGSizeMake(100, 100);
    self.playlistVideosCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layoutTwo];
    self.playlistVideosCollectionView.translatesAutoresizingMaskIntoConstraints = false;
    [self.playlistVideosCollectionView registerNib:[UINib nibWithNibName:@"YTTVStandardCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:standardReuseIdentifier];
    [self.playlistVideosCollectionView registerClass:[TYPlaylistCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.playlistVideosCollectionView setDelegate:self];
    [self.playlistVideosCollectionView setDataSource:self];
    
    [self.view addSubview:self.playlistVideosCollectionView];
    
    [self.channelVideosCollectionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.view withOffset:50];
    [self.channelVideosCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view];
    
    [self.channelVideosCollectionView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.view withOffset:50];
    
    //[self.channelVideosCollectionView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
    
    [self.channelVideosCollectionView autoSetDimension:ALDimensionHeight toSize:640];
    
    
    [self.playlistVideosCollectionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.view withOffset:0];
    
    [self.playlistVideosCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.channelVideosCollectionView withOffset:10];
    
    [self.playlistVideosCollectionView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.view withOffset:0];
    
    [self.playlistVideosCollectionView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view];
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    NSString *theTitle = nil;
    if (collectionView == self.channelVideosCollectionView)
    {
        theTitle = @"Your Videos";
    } else {
        theTitle = _backingSectionLabels[indexPath.section];
    }
    
    if (kind == UICollectionElementKindSectionHeader) {
        TYPlaylistCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        headerView.title.text = theTitle;
        reusableview = headerView;
    }
    
    return reusableview;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
  //  [self.view printRecursiveDescription];

}


- (void)fetchUserDetailsWithCompletionBlock:(void(^)(NSDictionary *finishedDetails))completionBlock
{
    NSMutableDictionary *playlists = [NSMutableDictionary new];
    _backingSectionLabels = [NSMutableArray new];
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    NSString *channelID = userDetails[@"channelID"];
    [[KBYourTube sharedInstance] getChannelVideos:channelID completionBlock:^(KBYTChannel *searchDetails) {
        
        //self.featuredVideosChannel = searchDetails;
        self.channelVideos = searchDetails.videos;
        [[self channelVideosCollectionView] reloadData];
        
        
    } failureBlock:^(NSString *error) {
        
    }];
    
    NSArray *results = userDetails[@"results"];
    NSInteger playlistCount = 0;
    for (KBYTSearchResult *result in results)
    {
        if (result.resultType ==kYTSearchResultTypePlaylist)
        {
            [_backingSectionLabels addObject:result.title];
        }
    }
    playlistCount = [_backingSectionLabels count];
    __block NSInteger currentIndex = 0;
    for (KBYTSearchResult *result in results)
    {
        if (result.resultType ==kYTSearchResultTypePlaylist)
        {
            [[KBYourTube sharedInstance] getPlaylistVideos:result.videoId completionBlock:^(KBYTPlaylist *searchDetails) {
                
                playlists[result.title] = searchDetails.videos;
                currentIndex++;
                if (currentIndex == playlistCount)
                {
                    completionBlock(playlists);
                }
               
            } failureBlock:^(NSString *error) {
                
                
                
            }];
        }
    }
 
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (collectionView == self.channelVideosCollectionView)
    {
        return CGSizeMake(640, 480);
    } else {
        return CGSizeMake(320, 340);
    }
 
}
 
 */


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (collectionView == self.channelVideosCollectionView)
    {
        return 1;
    } else {
        return [_backingSectionLabels count];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (collectionView == self.channelVideosCollectionView)
    {
        count = self.channelVideos.count;
        
    } else if (collectionView == self.playlistVideosCollectionView)
    {
        NSString *titleForSection = [_backingSectionLabels objectAtIndex:section];
        NSArray *arrayForSection = self.playlistDictionary[titleForSection];
        return [arrayForSection count];
    }
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == self.channelVideosCollectionView) {
        
        YTTVFeaturedCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:featuredReuseIdentifier forIndexPath:indexPath];
        if ([self.channelVideos count] > 0)
        {
            KBYTSearchResult *currentItem = [self.channelVideos objectAtIndex:indexPath.row];
            NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
            UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
            [cell.featuredImage sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
        } else {
            //  NSString *imageFileName = [NSString stringWithFormat:@"feature-%li.jpg", indexPath.row];
            cell.featuredImage.image = [UIImage imageNamed:@"YTPlaceholder"];
        }
        
        return cell;
    } else if (collectionView == self.playlistVideosCollectionView)
    {
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:standardReuseIdentifier forIndexPath:indexPath];
    
        NSString *titleForSection = [_backingSectionLabels objectAtIndex:indexPath.section];
        
        NSArray *arrayForSection = self.playlistDictionary[titleForSection];
        
        KBYTSearchResult *currentItem = [arrayForSection objectAtIndex:indexPath.row];
        NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
        UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
        [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
        cell.title.text = currentItem.title;
        
        return cell;
    }
    
    UICollectionViewCell *cell = [[UICollectionViewCell alloc] init];
    return cell;
    
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.channelVideosCollectionView)
    {
        KBYTSearchResult *currentItem = [self.channelVideos objectAtIndex:indexPath.row];
        [self playFirstStreamForResult:currentItem];
    } else {
        
        NSString *titleForSection = [_backingSectionLabels objectAtIndex:indexPath.section];
        NSArray *arrayForSection = self.playlistDictionary[titleForSection];
        
        NSArray *subarray = [arrayForSection subarrayWithRange:NSMakeRange(indexPath.row, arrayForSection.count - indexPath.row)];
        [self playAllSearchResults:subarray];
        
    }
}

- (void)playAllSearchResults:(NSArray *)searchResults
{
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

- (void)itemDidFinishPlaying:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
    [self dismissViewControllerAnimated:true completion:nil];
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
