//
//  TYUserViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/7/16.
//
//

#import <UIKit/UIKit.h>
#import "UIView+RecursiveFind.h"
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

@interface TYBaseGridViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    NSMutableArray *_backingSectionLabels;
}
@property (nonatomic, strong) UICollectionView *featuredVideosCollectionView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *featuredVideos;
@property (nonatomic, strong) NSDictionary *playlistDictionary;
@property (nonatomic, strong) NSArray *sectionLabels;

- (void)showChannel:(KBYTSearchResult *)searchResult;
- (void)playAllSearchResults:(NSArray *)searchResults;
- (void)playFirstStreamForResult:(KBYTSearchResult *)searchResult;
- (id)initWithSections:(NSArray *)sections;
- (void)reloadCollectionViews;
- (NSString *)titleForSection:(NSInteger)section;
- (NSArray *)arrayForCollectionView:(UICollectionView *)theView;

@end


