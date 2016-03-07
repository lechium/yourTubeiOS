//
//  FirstViewController.h
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView1;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView2;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView3;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView4;
@property (nonatomic, strong) NSString *reuseFeatureID;
@property (nonatomic, strong) NSString *reuseStandardID;
@property (nonatomic, strong) NSDictionary *featuredVideosDict;
@property (nonatomic, strong) NSArray *featuredVideos;

@end

