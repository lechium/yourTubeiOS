//
//  TYUserViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/7/16.
//
//

#import "TYBaseGridViewController.h"
#import "YTTVStandardCollectionViewCell.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "YTKBPlayerViewController.h"
#import "KBYTQueuePlayer.h"
#import "MarqueeLabel.h"
#import "CollectionViewLayout.h"
#import "YTTVFeaturedCollectionViewCell.h"

@interface TYBaseGridCollectionHeaderView : UICollectionReusableView
{
    
}
@property (strong, nonatomic) UILabel *title;

@end

@implementation TYBaseGridCollectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.title = [[UILabel alloc] initWithFrame:CGRectMake(100, 20, 400, 40)];
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


@interface TYBaseGridViewController ()
{
    CGFloat _totalHeight;
}

@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;


@end

static NSString * const featuredReuseIdentifier = @"FeaturedCell";
static NSString * const standardReuseIdentifier = @"StandardCell";

@implementation TYBaseGridViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    NSArray *results = userDetails[@"results"];
    _backingSectionLabels = [NSMutableArray new];
    
    for (KBYTSearchResult *result in results)
    {
        if (result.resultType == kYTSearchResultTypePlaylist)
        {
            [_backingSectionLabels addObject:result.title];
        }
    }
   // [self fetchUserDetails];
    [self setupViews];
    [self fetchUserDetailsWithCompletionBlock:^(NSDictionary *finishedDetails) {
        
        self.playlistDictionary = finishedDetails;
        
        [self reloadCollectionViews];
    }];
    // Do any additional setup after loading the view.
}

- (void)reloadCollectionViews
{

    NSInteger i = 0;
    for (i = 0; i < [_backingSectionLabels count]; i++)
    {
        UICollectionView *collectionView = (UICollectionView*)[self.view viewWithTag:60+i];
       // NSLog(@"collectionView: %@", collectionView);
        if ([collectionView isKindOfClass:[UICollectionView class]])
        {
            [collectionView reloadData];
        }
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
 
    NSLog(@"keyPath: %@", keyPath);
    id newValue = change[@"new"];
    NSLog(@"newValue: %@", newValue);
}

- (void)setupViews
{
    /*
    self.scrollView = [[UIScrollView alloc] initForAutoLayout];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = false;
    [self.mainView addSubview:self.scrollView];
   // [self.scrollView autoSetDimension:ALDimensionHeight toSize:940];
  //  [self.scrollView auto]
    [self.scrollView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
    [self.scrollView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
    //[self.scrollView autoPinEdgesToSuperviewEdges];
    [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.scrollView autoPinToTopLayoutGuideOfViewController:self withInset:0];
    [self.scrollView autoPinToBottomLayoutGuideOfViewController:self withInset:0];
    // [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    self.scrollView.userInteractionEnabled = true;
    //self.scrollView.panGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    self.scrollView.scrollEnabled = true;
    self.scrollView.directionalLockEnabled = false;
     */
   
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
    
    [self.channelVideosCollectionView registerClass:[TYBaseGridCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.channelVideosCollectionView setDelegate:self];
    [self.channelVideosCollectionView setDataSource:self];
    [self.scrollView addSubview:self.channelVideosCollectionView];
    
    [self.channelVideosCollectionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.scrollView withOffset:50];
    [self.channelVideosCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.scrollView];
    
    [self.channelVideosCollectionView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.scrollView withOffset:50];
    
    [self.channelVideosCollectionView autoSetDimension:ALDimensionHeight toSize:640];
    
    [self.channelVideosCollectionView autoSetDimension:ALDimensionWidth toSize:1920];
    
    
    CollectionViewLayout *layoutTwo = [CollectionViewLayout new];
    
    layoutTwo.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layoutTwo.minimumInteritemSpacing = 10;
    layoutTwo.minimumLineSpacing = 50;
    layoutTwo.itemSize = CGSizeMake(320, 420);
    layoutTwo.sectionInset = UIEdgeInsetsMake(35, 0, 20, 0);
    layoutTwo.headerReferenceSize = CGSizeMake(100, 100);
    
    NSInteger i = 0;
    _totalHeight = 640;
    for (i = 0; i < [_backingSectionLabels count]; i++)
    {

        UICollectionView *collectionView  = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layoutTwo];
        //collectionView.scrollEnabled = true;
        collectionView.tag = 60 + i;
        collectionView.translatesAutoresizingMaskIntoConstraints = false;
        [collectionView registerNib:[UINib nibWithNibName:@"YTTVStandardCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:standardReuseIdentifier];
        [collectionView registerClass:[TYBaseGridCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
        [collectionView setDelegate:self];
        [collectionView setDataSource:self];
        
       
        [self.scrollView addSubview:collectionView];
 
        
        if (i == 0) //first one
        {
            [collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.channelVideosCollectionView withOffset:-50];
        } else {
            UIView *previousView = [self.view viewWithTag:collectionView.tag-1];
            [collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousView withOffset:20];
            
        }
        
        [collectionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.scrollView withOffset:0];
        [collectionView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.scrollView withOffset:0];

        _totalHeight+=550;
        
          [collectionView autoSetDimension:ALDimensionHeight toSize:530];
        if (i == [_backingSectionLabels count]-1)
        {
        
           // [collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

        }
    }
    
  
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
        TYBaseGridCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        headerView.title.text = theTitle;
        reusableview = headerView;
    }
    
    return reusableview;
}


- (void)viewDidLayoutSubviews
{
    LOG_SELF;
      [[self scrollView] setContentSize:CGSizeMake(1920, _totalHeight)];
      DLog(@"insets : %@", NSStringFromUIEdgeInsets(self.scrollView.contentInset));
  //  DLog(@"total height: %f", _totalHeight);
    
    [self.view printRecursiveDescription];

}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    LOG_SELF;
    CGPoint offset = self.scrollView.contentOffset;
    CGFloat height = self.view.bounds.size.height;
    DLog(@"offset: %@", NSStringFromCGPoint(offset));
    UICollectionView *collectionView = (UICollectionView*)[[context nextFocusedView] superview];
    if (collectionView.frame.origin.y > height)
    {
       
        CGFloat newY = collectionView.frame.origin.y - height;
        offset.y = newY;
        DLog(@"we needs to scroll: %f", newY);
        dispatch_async(dispatch_get_main_queue(), ^{
           //  [self.scrollView setContentOffset:offset animated:true];
        });
      //  [self.scrollView setContentOffset:offset animated:true];
    }
    
}


- (void)fetchUserDetailsWithCompletionBlock:(void(^)(NSDictionary *finishedDetails))completionBlock
{
    NSMutableDictionary *playlists = [NSMutableDictionary new];
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    NSString *channelID = userDetails[@"channelID"];
    [[KBYourTube sharedInstance] getChannelVideos:channelID completionBlock:^(NSDictionary *searchDetails) {
        
        //self.featuredVideosDict = searchDetails;
        self.channelVideos = searchDetails[@"results"];
          [[self channelVideosCollectionView] reloadData];
        
        
    } failureBlock:^(NSString *error) {
        
    }];
    
    NSArray *results = userDetails[@"results"];
    NSInteger playlistCount = 0;
    /*
    for (KBYTSearchResult *result in results)
    {
        if (result.resultType == kYTSearchResultTypePlaylist)
        {
            [_backingSectionLabels addObject:result.title];
        }
    }
     */
    playlistCount = [_backingSectionLabels count];
    __block NSInteger currentIndex = 0;
    for (KBYTSearchResult *result in results)
    {
        if (result.resultType == kYTSearchResultTypePlaylist)
        {
            [[KBYourTube sharedInstance] getPlaylistVideos:result.videoId completionBlock:^(NSDictionary *searchDetails) {
                
                playlists[result.title] = searchDetails[@"results"];
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
        
    } else
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
    } else 
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
