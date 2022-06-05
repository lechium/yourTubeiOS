//
//  TYBaseGridViewController.h
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
#import "TYTVHistoryManager.h"
#import "KBYTChannelHeaderView.h"

@interface TYBaseGridCollectionHeaderView : UICollectionReusableView
{
    
}
@property (strong, nonatomic) UILabel *title;
@property (readwrite, assign) CGFloat topOffset; //when 0,0 is selected, change this offset to shift the header up
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
- (void)updateTopOffset:(CGFloat)offset;

@end


@interface TYBaseGridViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>
{
    NSMutableArray *_backingSectionLabels;
    
}


@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UICollectionView *featuredVideosCollectionView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) KBYTChannel *featuredChannel;
@property (nonatomic, strong) NSArray *featuredVideos;
@property (nonatomic, strong) NSDictionary *playlistDictionary;
@property (nonatomic, strong) NSArray *sectionLabels;
@property (nonatomic, weak) UICollectionViewCell *focusedCollectionCell;
@property (readwrite, assign) CGFloat totalHeight;
@property (nonatomic, strong) void (^alertHandler)(UIAlertAction *action);
@property (nonatomic, strong) void (^channelAlertHandler)(UIAlertAction *action);
@property (nonatomic, strong) NSLayoutConstraint *featuredHeightConstraint;

- (KBYTChannel *)channelForCollectionView:(UICollectionView *)theView;
- (KBYTSearchResult *)searchResultFromFocusedCell;
- (KBYTChannelHeaderView *)headerview;
- (void)showChannel:(KBYTSearchResult *)searchResult;
- (void)playAllSearchResults:(NSArray *)searchResults;
- (void)playFirstStreamForResult:(KBYTSearchResult *)searchResult;
- (id)initWithSections:(NSArray *)sections;
- (void)reloadCollectionViews;
- (NSString *)titleForSection:(NSInteger)section;
- (NSArray *)arrayForCollectionView:(UICollectionView *)theView;
- (UICollectionView *)collectionViewFromCell:(UICollectionViewCell *)cell;
-(void) handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)focusedCell:(YTTVStandardCollectionViewCell *)focusedCell;
@end


