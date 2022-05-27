//
//  FirstViewController.h
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import <UIKit/UIKit.h>
#import "UIView+RecursiveFind.h"

@class KBYTPlaylist, KBYTChannel;

@interface FirstViewController : UIViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView1;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView2;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView3;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView4;
@property (nonatomic, strong) NSString *reuseFeatureID;
@property (nonatomic, strong) NSString *reuseStandardID;
@property (nonatomic, strong) KBYTChannel *featuredVideosChannels;
@property (nonatomic, strong) NSArray *featuredVideos;
@property (nonatomic, strong) KBYTChannel *popularVideosChannel;
@property (nonatomic, strong) NSArray *popularVideos;
@property (nonatomic, strong) KBYTChannel *musicVideosChannel;
@property (nonatomic, strong) NSArray *musicVideos;
@property (nonatomic, strong) KBYTChannel *sportsVideosChannel;
@property (nonatomic, strong) NSArray *sportsVideos;

@end

