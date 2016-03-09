//
//  KBYTChannelViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/9/16.
//
//

#import "KBYTChannelViewController.h"
#import "YTTVStandardCollectionViewCell.h"
#import "KBYourTube.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"

@interface KBYTChannelViewController ()

@property (nonatomic, weak) IBOutlet UICollectionView * channelCollectionView;


@end

@implementation KBYTChannelViewController

@synthesize authorLabel, bannerImage, subscribersLabel, subscribers, channelTitle;

static NSString * const reuseIdentifier = @"NewStandardCell";

- (void)viewDidLoad {
    [super viewDidLoad];
   
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIImage *banner = [UIImage imageNamed:@"Banner"];
    NSURL *imageURL = [NSURL URLWithString:self.bannerURL];
    [self.bannerImage sd_setImageWithURL:imageURL placeholderImage:banner options:SDWebImageAllowInvalidSSLCertificates];
    self.authorLabel.text = self.channelTitle;
    self.subscribersLabel.text = self.subscribers;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return self.searchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YTTVStandardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    KBYTSearchResult *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    
    NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
    UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
    [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
    cell.title.text = currentItem.title;
    // Configure the cell
    
    return cell;
}

- (void)itemDidFinishPlaying:(NSNotification *)n
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
    //[[self.presentingViewController navigationController] popViewControllerAnimated:true];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    KBYTSearchResult *searchResult = [self.searchResults objectAtIndex:indexPath.row];
    [self playFirstStreamForResult:searchResult];
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
        
        [self presentViewController:playerView animated:true completion:nil];
        //[[self.presentingViewController navigationController] pushViewController:playerView animated:true];
        [playerView.player play];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:singleItem];
        
        
    } failureBlock:^(NSString *error) {
        
    }];
    
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
