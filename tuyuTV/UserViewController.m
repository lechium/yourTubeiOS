//
//  FirstViewController.m
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import "UserViewController.h"
#import "YTTVFeaturedCollectionViewCell.h"
#import "YTTVStandardCollectionViewCell.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "YTKBPlayerViewController.h"
#import "KBYTQueuePlayer.h"
#import "MarqueeLabel.h"

@interface UserViewController ()

@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;

@end

@implementation UserViewController

@synthesize reuseFeatureID, reuseStandardID, playerView;

- (void)viewDidLoad {
    
    self.reuseFeatureID = @"FeaturedCell";
    self.reuseStandardID = @"StandardCell";
    [super viewDidLoad];
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    NSString *channelID = userDetails[@"channelID"];
    [[KBYourTube sharedInstance] getChannelVideos:channelID completionBlock:^(NSDictionary *searchDetails) {
        
        self.featuredVideosDict = searchDetails;
        self.featuredVideos = searchDetails[@"results"];
        [[self collectionView1] reloadData];
        
        
    } failureBlock:^(NSString *error) {
    
    }];
    
    NSArray *results = userDetails[@"results"];
    if ([results count] > 0)
    {
        KBYTSearchResult *firstResult = results[0];
        if (firstResult.resultType == kYTSearchResultTypePlaylist)
        {
            self.firstLabel.text = firstResult.title;
            [[KBYourTube sharedInstance] getPlaylistVideos:firstResult.videoId completionBlock:^(NSDictionary *searchDetails) {
                
                self.popularVideosDict = searchDetails;
                self.popularVideos = searchDetails[@"results"];
                [[self collectionView2] reloadData];
                
            } failureBlock:^(NSString *error) {
                
                
            }];
        }
        
        if ([results count] > 1)
        {
            KBYTSearchResult *secondResult = results[1];
            self.secondLabel.text = secondResult.title;
            [[KBYourTube sharedInstance] getPlaylistVideos:secondResult.videoId completionBlock:^(NSDictionary *searchDetails) {
                
                self.musicVideosDict = searchDetails;
                self.musicVideos = searchDetails[@"results"];
                [[self collectionView3] reloadData];
                
            } failureBlock:^(NSString *error) {
                
                
            }];
        }
       
        if ([results count] > 2)
        {
            KBYTSearchResult *thirdResult = results[2];
            self.thirdLabel.text = thirdResult.title;
            [[KBYourTube sharedInstance] getPlaylistVideos:thirdResult.videoId completionBlock:^(NSDictionary *searchDetails) {
                
                self.sportsVideosDict = searchDetails;
                self.sportsVideos = searchDetails[@"results"];
                [[self collectionView4] reloadData];
                
            } failureBlock:^(NSString *error) {
                
                
            }];
            
        }
        
        
       
    }
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidLayoutSubviews
{
    self.scrollView.contentSize = CGSizeMake(1920, 2220);
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
            NSArray *subarray = [self.popularVideos subarrayWithRange:NSMakeRange(indexPath.row, self.popularVideos.count - indexPath.row)];
            [self playAllSearchResults:subarray];
        }
       
    } else if (collectionView == self.collectionView3)
    {
        if (self.musicVideos.count > 0)
        {
            NSArray *subarray = [self.musicVideos subarrayWithRange:NSMakeRange(indexPath.row, self.musicVideos.count - indexPath.row)];
            [self playAllSearchResults:subarray];
        }
        
    } else if (collectionView == self.collectionView4)
    {
        if (self.sportsVideos.count > 0)
        {
            NSArray *subarray = [self.sportsVideos subarrayWithRange:NSMakeRange(indexPath.row, self.sportsVideos.count - indexPath.row)];
            [self playAllSearchResults:subarray];
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

- (void)itemDidFinishPlaying:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
    [self dismissViewControllerAnimated:true completion:nil];
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
            cell.title.text = currentItem.title;
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
            cell.title.text = currentItem.title;
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
            cell.title.text = currentItem.title;
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
