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
#import "KBYTChannelViewController.h"

static int tagOffset = 60;
static int headerTagOffset = 70;

@interface KBCollectionView: UICollectionView

@end

@implementation KBCollectionView

/*
-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
for(NSInteger i=0 ; i < self.numberOfSections; i++) {
    for (NSInteger j=0 ; j < [self numberOfItemsInSection:i]; j++) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:j inSection:i];
        [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
    }
}
}
 
 */

@end

@interface TYBaseGridCollectionHeaderView : UICollectionReusableView
{
    
}
@property (strong, nonatomic) UILabel *title;
@property (readwrite, assign) CGFloat topOffset;
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
- (void)updateTopOffset:(CGFloat)offset;

@end



@implementation TYBaseGridCollectionHeaderView

- (void)updateTopOffset:(CGFloat)offset
{
    self.topOffset = offset;
    [self.topConstraint setConstant:-offset];
    if (offset > 0)
    {
     //   self.backgroundColor = [UIColor redColor];
    }
    [self layoutIfNeeded];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
       // self.title = [[UILabel alloc] initWithFrame:CGRectMake(100, 0, 400, 40)];
        self.title = [[UILabel alloc] initForAutoLayout];
        [self addSubview:self.title];
        self.topOffset = self.topOffset;
        //self.topConstraint = [self.title autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self withOffset:-self.topOffset];
        self.topOffset = -40;
        self.topConstraint = [self.title autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-self.topOffset];
        [self.title autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:100];
        self.title.textColor = [UIColor whiteColor];
        self.title.font = [UIFont systemFontOfSize:40];
     //   [self autoSetDimension:ALDimensionHeight toSize:200];
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

- (id)initWithSections:(NSArray *)sections
{
    self = [super init];
    self.sectionLabels = sections;
    return self;
}

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
    
    if (userDetails[@"channels"] != nil)
    {
        [_backingSectionLabels addObject:@"Channels"];
    }
    
    self.sectionLabels = _backingSectionLabels;

    [self setupViews];
    [self fetchUserDetailsWithCompletionBlock:^(NSDictionary *finishedDetails) {
        
        self.playlistDictionary = finishedDetails;
        
        [self reloadCollectionViews];
    }];
    // Do any additional setup after loading the view.
}

- (void)reloadCollectionViews
{
    ;
    NSInteger i = 0;
    for (i = 0; i < [_backingSectionLabels count]; i++)
    {
        UICollectionView *collectionView = (UICollectionView*)[self.view viewWithTag:tagOffset+i];
       // NSLog(@"collectionView: %@", collectionView);
        if ([collectionView isKindOfClass:[UICollectionView class]])
        {
            [collectionView reloadData];
        }
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
 

}

- (void)setupViews
{
    self.scrollView = [[UIScrollView alloc] initForAutoLayout];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.scrollView];

    //left here for posterity, this is why they were not working, do NOT pin the size of a UIScrollView, just
    //its edges!!!
    
    //[self.scrollView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
    //[self.scrollView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
    [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self.scrollView autoPinToTopLayoutGuideOfViewController:self withInset:0];
    [self.scrollView autoPinToBottomLayoutGuideOfViewController:self withInset:0];
    self.scrollView.userInteractionEnabled = true;
    self.scrollView.scrollEnabled = true;
    self.scrollView.directionalLockEnabled = false;
    
    CollectionViewLayout *layout = [CollectionViewLayout new];
    layout.minimumInteritemSpacing = 50;
    layout.minimumLineSpacing = 50;
    layout.itemSize = CGSizeMake(640, 480);
    layout.sectionInset = UIEdgeInsetsMake(-5, 0, 0, 0);

    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //layout.sectionInset = UIEdgeInsetsZero;
    self.channelVideosCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.channelVideosCollectionView.tag = 666;
    self.channelVideosCollectionView.translatesAutoresizingMaskIntoConstraints = false;
    [self.channelVideosCollectionView registerNib:[UINib nibWithNibName:@"YTTVFeaturedCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:featuredReuseIdentifier];
    
    [self.channelVideosCollectionView registerClass:[TYBaseGridCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.channelVideosCollectionView setDelegate:self];
    [self.channelVideosCollectionView setDataSource:self];
    [self.scrollView addSubview:self.channelVideosCollectionView];
    
    [self.channelVideosCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.scrollView withOffset:50];
 //   [self.channelVideosCollectionView autoPinToTopLayoutGuideOfViewController:self withInset:50];
    
    [self.channelVideosCollectionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.scrollView withOffset:20];
    
    [self.channelVideosCollectionView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.scrollView withOffset:20];
    
    [self.channelVideosCollectionView autoSetDimension:ALDimensionHeight toSize:480];
    
    [self.channelVideosCollectionView autoSetDimension:ALDimensionWidth toSize:1920];
    
    
    
    
    NSInteger i = 0;
    _totalHeight = 640;
    for (i = 0; i < [_backingSectionLabels count]; i++)
    {

        CollectionViewLayout *layoutTwo = [CollectionViewLayout new];
        
        layoutTwo.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layoutTwo.minimumInteritemSpacing = 10;
        layoutTwo.minimumLineSpacing = 50;
        layoutTwo.itemSize = CGSizeMake(320, 340);
        layoutTwo.sectionInset = UIEdgeInsetsMake(35, 0, 20, 0);
        layoutTwo.headerReferenceSize = CGSizeMake(100, 150);
        UICollectionView *collectionView  = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layoutTwo];
        //collectionView.scrollEnabled = true;
        collectionView.tag = tagOffset + i;
        collectionView.translatesAutoresizingMaskIntoConstraints = false;
        [collectionView registerNib:[UINib nibWithNibName:@"YTTVStandardCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:standardReuseIdentifier];
        [collectionView registerClass:[TYBaseGridCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
        [collectionView setDelegate:self];
        [collectionView setDataSource:self];
        
       
        [self.scrollView addSubview:collectionView];
 
        
        if (i == 0) //first one
        {
            [collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.channelVideosCollectionView withOffset:30];
        } else {
            UIView *previousView = [self.view viewWithTag:collectionView.tag-1];
            [collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousView withOffset:20];
            
        }
        [collectionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.scrollView withOffset:-50];
        
     
        [collectionView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.scrollView withOffset:0];

        _totalHeight+=540;
        
          [collectionView autoSetDimension:ALDimensionHeight toSize:520];
        if (i == [_backingSectionLabels count]-1)
        {
            if ([[KBYourTube sharedInstance] userDetails][@"channels"] != nil)
            {
                //may need to adjust offset of header title cuz channel pics are bigger
            }
        
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
        
        NSInteger viewTag = collectionView.tag - tagOffset;
        theTitle = _backingSectionLabels[viewTag];
    }
    
    if (kind == UICollectionElementKindSectionHeader) {
        TYBaseGridCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        headerView.title.text = theTitle;
        reusableview = headerView;
        reusableview.tag = (collectionView.tag - tagOffset)+ headerTagOffset;
    }
    
    return reusableview;
}


- (void)viewDidLayoutSubviews
{
    ;
      [[self scrollView] setContentSize:CGSizeMake(1920, _totalHeight)];

   // [self.view printRecursiveDescription];

}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
 
    [self previouslyFocusedCell:(YTTVStandardCollectionViewCell*)context.previouslyFocusedView];
    [self focusedCell:(YTTVStandardCollectionViewCell*)context.nextFocusedView];
}

- (void)previouslyFocusedCell:(YTTVStandardCollectionViewCell *)focusedCell
{
    UICollectionView *cv = (UICollectionView*)[focusedCell superview];
    if (![cv isKindOfClass:[UICollectionView class]])
    {
        return;
    }
    if (cv == self.channelVideosCollectionView)
    {
        return;
    }
    NSInteger headerTag = (cv.tag - tagOffset) + headerTagOffset;
    TYBaseGridCollectionHeaderView *header = [cv viewWithTag:headerTag];
    [header updateTopOffset:-40];
}

- (void)focusedCell:(YTTVStandardCollectionViewCell *)focusedCell
{
    UICollectionView *cv = (UICollectionView*)[focusedCell superview];
    if (![cv isKindOfClass:[UICollectionView class]])
    {
        return;
    }
    if (cv == self.channelVideosCollectionView)
    {
        return;
    }
    NSIndexPath *indexPath = [cv indexPathForCell:focusedCell];
    NSInteger headerTag = (cv.tag - tagOffset) + headerTagOffset;
    TYBaseGridCollectionHeaderView *header = [cv viewWithTag:headerTag];
    
    if (indexPath.row == 0)
    {
        [header updateTopOffset:-20];
    } else {
        [header updateTopOffset:-40];
    }
}


- (void)fetchUserDetailsWithCompletionBlock:(void(^)(NSDictionary *finishedDetails))completionBlock
{
    ;
    NSMutableDictionary *playlists = [NSMutableDictionary new];
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    NSString *channelID = userDetails[@"channelID"];
    NSInteger adjustment = 0;
    if (userDetails[@"channels"] != nil)
    {
        playlists[@"Channels"] = userDetails[@"channels"];
        adjustment = 1;
    }
    [[KBYourTube sharedInstance] getChannelVideos:channelID completionBlock:^(NSDictionary *searchDetails) {

        self.channelVideos = searchDetails[@"results"];
          [[self channelVideosCollectionView] reloadData];
        
        
    } failureBlock:^(NSString *error) {
        
    }];
    
    NSArray *results = userDetails[@"results"];
    NSInteger playlistCount = 0;

    playlistCount = [_backingSectionLabels count]-adjustment;
    
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


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    ;
    NSInteger count = 0;
    if (collectionView == self.channelVideosCollectionView)
    {
        count = self.channelVideos.count;
        
    } else
    {
        return [[self arrayForCollectionView:collectionView] count];
    }
    
    return count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    ;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ;
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
    
        //NSInteger viewTag = collectionView.tag - tagOffset;
        NSArray *detailsArray = [self arrayForCollectionView:collectionView];

        KBYTSearchResult *currentItem = [detailsArray objectAtIndex:indexPath.row];
        NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
        UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
        [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
        cell.title.text = currentItem.title;
        
        return cell;
    }
    
}

- (void)showChannel:(KBYTSearchResult *)searchResult
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    KBYTChannelViewController *cv = [sb instantiateViewControllerWithIdentifier:@"channelViewController"];
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getChannelVideos:searchResult.videoId completionBlock:^(NSDictionary *searchDetails) {
        
        [SVProgressHUD dismiss];
        
        cv.searchResults = searchDetails[@"results"];
        cv.pageCount = 1;
        cv.nextHREF = searchDetails[@"loadMoreREF"];
        cv.bannerURL = searchDetails[@"banner"];
        cv.channelTitle = searchDetails[@"name"];
        cv.subscribers = searchDetails[@"subscribers"];
        
        [self presentViewController:cv animated:true completion:nil];
        //[self.navigationController pushViewController:cv animated:true];
        
    } failureBlock:^(NSString *error) {
        
    }];
}

- (NSString *)titleForSection:(NSInteger)section
{
    return [_backingSectionLabels objectAtIndex:section];
}

- (NSArray *)arrayForCollectionView:(UICollectionView *)theView
{
    NSInteger section = theView.tag - tagOffset;
    return self.playlistDictionary[[self titleForSection:section]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{

    if (collectionView == self.channelVideosCollectionView)
    {
        KBYTSearchResult *currentItem = [self.channelVideos objectAtIndex:indexPath.row];
        
        [self playFirstStreamForResult:currentItem];
    } else {
        
        NSArray *detailsArray = [self arrayForCollectionView:collectionView];
        KBYTSearchResult *selectedItem = [detailsArray objectAtIndex:indexPath.row];
        if (selectedItem.resultType == kYTSearchResultTypeChannel)
        {
            
            [self showChannel:selectedItem];
            return;
        }
        
        
        NSArray *subarray = [detailsArray subarrayWithRange:NSMakeRange(indexPath.row, detailsArray.count - indexPath.row)];
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
