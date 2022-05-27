//
//  FirstViewController.h
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

@class KBYTPlaylist, KBYTChannel;

@interface UserViewController : UIViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView1;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView2;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView3;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView4;

@property (nonatomic, strong) IBOutlet UILabel *firstLabel;
@property (nonatomic, strong) IBOutlet UILabel *secondLabel;
@property (nonatomic, strong) IBOutlet UILabel *thirdLabel;


@property (nonatomic, strong) NSString *reuseFeatureID;
@property (nonatomic, strong) NSString *reuseStandardID;
@property (nonatomic, strong) KBYTChannel *featuredVideosChannel;
@property (nonatomic, strong) NSArray *featuredVideos;
@property (nonatomic, strong) KBYTPlaylist *popularVideosChannel;
@property (nonatomic, strong) NSArray *popularVideos;
@property (nonatomic, strong) KBYTPlaylist *musicVideosChannel;
@property (nonatomic, strong) NSArray *musicVideos;
@property (nonatomic, strong) KBYTPlaylist *sportsVideosChannels;
@property (nonatomic, strong) NSArray *sportsVideos;

@end

