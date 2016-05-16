//
//  FirstViewController.m
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import "FirstViewController.h"
#import "YTTVFeaturedCollectionViewCell.h"
#import "YTTVStandardCollectionViewCell.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "YTKBPlayerViewController.h"
#import "MarqueeLabel.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

@synthesize reuseFeatureID, reuseStandardID;

- (void)viewDidLoad {
    
    self.reuseFeatureID = @"FeaturedCell";
    self.reuseStandardID = @"StandardCell";
    [super viewDidLoad];
    [[KBYourTube sharedInstance] getFeaturedVideosWithCompletionBlock:^(NSDictionary *searchDetails) {
        
        self.featuredVideosDict = searchDetails;
        self.featuredVideos = searchDetails[@"results"];
        [[self collectionView1] reloadData];
        
        
    } failureBlock:^(NSString *error) {
    
    }];
    
    
    
    [[KBYourTube sharedInstance] getChannelVideos:KBYTPopularChannelID completionBlock:^(NSDictionary *searchDetails) {
    
        self.popularVideosDict = searchDetails;
        self.popularVideos = searchDetails[@"results"];
        [[self collectionView2] reloadData];
        
    } failureBlock:^(NSString *error) {
        
    
    }];
    
    [[KBYourTube sharedInstance] getChannelVideos:KBYTMusicChannelID completionBlock:^(NSDictionary *searchDetails) {
        
        self.musicVideosDict = searchDetails;
        self.musicVideos = searchDetails[@"results"];
        [[self collectionView3] reloadData];
        
    } failureBlock:^(NSString *error) {
        
        
    }];
    
    [[KBYourTube sharedInstance] getChannelVideos:KBYTSportsChannelID completionBlock:^(NSDictionary *searchDetails) {
        
        self.sportsVideosDict = searchDetails;
        self.sportsVideos = searchDetails[@"results"];
        [[self collectionView4] reloadData];
        
    } failureBlock:^(NSString *error) {
        
        
    }];
    

    // Do any additional setup after loading the view, typically from a nib.
}



- (void)itemDidFinishPlaying:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
    [self dismissViewControllerAnimated:true completion:nil];
}


- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    LOG_SELF;
    CGPoint offset = self.scrollView.contentOffset;
    DLog(@"offset: %@", NSStringFromCGPoint(offset));
    DLog(@"nextView: %@", [[context nextFocusedView] superview]);
}


- (void)viewDidLayoutSubviews
{
        LOG_SELF;
    self.scrollView.contentSize = CGSizeMake(1920, 2220);
    DLog(@"insets : %i", self.collectionView1.translatesAutoresizingMaskIntoConstraints);
    

     //[self.view printRecursiveDescription];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    LOG_SELF;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    LOG_SELF;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 50;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 50;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0.0, 50.0, 0.0, 50.0);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.collectionView1)
    {
        if ([self.featuredVideos count] > 0)
        {
            return self.featuredVideos.count;
        }
        return 8;
    } else if (collectionView == self.collectionView2) {
    
        if ([self.popularVideos count] > 0)
        {
            return self.popularVideos.count;
        }
        return 10;
    } else if (collectionView == self.collectionView3) {
        
        if ([self.musicVideos count] > 0)
        {
            return self.musicVideos.count;
        }
        return 10;
        
    } else if (collectionView == self.collectionView4) {
        
        if ([self.sportsVideos count] > 0)
        {
            return self.sportsVideos.count;
        }
        return 10;
        
    } else {
        return 10;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.collectionView1)
    {
        if (self.featuredVideos.count > 0)
        {
            KBYTSearchResult *currentItem = [self.featuredVideos objectAtIndex:indexPath.row];
            [self playFirstStreamForResult:currentItem];
        }
    } else if (collectionView == self.collectionView2)
    {
        if (self.popularVideos.count > 0)
        {
            KBYTSearchResult *currentItem = [self.popularVideos objectAtIndex:indexPath.row];
            [self playFirstStreamForResult:currentItem];
        }
       
    } else if (collectionView == self.collectionView3)
    {
        if (self.musicVideos.count > 0)
        {
            KBYTSearchResult *currentItem = [self.musicVideos objectAtIndex:indexPath.row];
            [self playFirstStreamForResult:currentItem];
        }
        
    } else if (collectionView == self.collectionView4)
    {
        if (self.sportsVideos.count > 0)
        {
            KBYTSearchResult *currentItem = [self.sportsVideos objectAtIndex:indexPath.row];
            [self playFirstStreamForResult:currentItem];
        }
        
    }
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.collectionView1)
    {
        YTTVFeaturedCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseFeatureID forIndexPath:indexPath];
      if ([self.featuredVideos count] > 0)
      {
          KBYTSearchResult *currentItem = [self.featuredVideos objectAtIndex:indexPath.row];
          NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
       //   NSLog(@"imageURL: %@", imageURL);
          UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
          [cell.featuredImage sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
      } else {
        //  NSString *imageFileName = [NSString stringWithFormat:@"feature-%li.jpg", indexPath.row];
          cell.featuredImage.image = [UIImage imageNamed:@"YTPlaceholder"];
      }
       
        return cell;
    }
    
    if (collectionView == self.collectionView2)
    {
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseStandardID forIndexPath:indexPath];
        if (self.popularVideos.count > 0)
        {
            KBYTSearchResult *currentItem = [self.popularVideos objectAtIndex:indexPath.row];
            NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
            UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
            [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
            cell.title.text = [NSString stringWithFormat:@"%@ - %@", currentItem.author, currentItem.title];
        } else {
            cell.image.image = [UIImage imageNamed:@"YTPlaceholder"];
            cell.title.text = @"Movie Title";
        }
        return cell;
    }
    
    if (collectionView == self.collectionView3)
    {
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseStandardID forIndexPath:indexPath];
        if (self.musicVideos.count > 0)
        {
            KBYTSearchResult *currentItem = [self.musicVideos objectAtIndex:indexPath.row];
            NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
            UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
            [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
            cell.title.text = [NSString stringWithFormat:@"%@ - %@", currentItem.author, currentItem.title];
        } else {
            cell.image.image = [UIImage imageNamed:@"YTPlaceholder"];
            cell.title.text = @"Movie Title";
        }
        return cell;
    }
    
    if (collectionView == self.collectionView4)
    {
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseStandardID forIndexPath:indexPath];
        
        if (self.sportsVideos.count > 0)
        {
            KBYTSearchResult *currentItem = [self.sportsVideos objectAtIndex:indexPath.row];
            NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
            UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
            [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
            cell.title.text = [NSString stringWithFormat:@"%@ - %@", currentItem.author, currentItem.title];
        } else {
            cell.image.image = [UIImage imageNamed:@"YTPlaceholder"];
            cell.title.text = @"Movie Title";
        }
        return cell;
    }
    
    return [[UICollectionViewCell alloc] init];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
