//
//  TYUserViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/7/16.
//
//

#import <UIKit/UIKit.h>
#import "UIView+RecursiveFind.h"

@interface TYUserViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    NSMutableArray *_backingSectionLabels;
}
@property (nonatomic, strong) UICollectionView *channelVideosCollectionView;
@property (nonatomic, strong) UICollectionView *playlistVideosCollectionView;
@property (nonatomic, strong) NSArray *channelVideos;
@property (nonatomic, strong) NSDictionary *playlistDictionary;
@property (nonatomic, strong) NSArray *sectionLabels;

@end


