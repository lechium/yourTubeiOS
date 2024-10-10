//
//  KBFeaturedViewController.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 2/28/17.
//  Copyright © 2017 nito, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KBProtocols.h"
#import "KBYTChannelHeaderView.h"

@class KBModelItem, KBSection;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ScrollDirection) {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
};

@class KBYTTab;

//UITableViewController
@interface KBShelfViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSourcePrefetching, UITabBarDelegate>

//@property (nonatomic, copy, nullability) returnType (^blockName)(parameterTypes);
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(id<KBCollectionItemProtocol> item, BOOL longPress, NSInteger row, NSInteger section);
@property (nonatomic, copy, nullable) void (^itemFocusedBlock)(NSInteger row, NSInteger section, UICollectionView *collectionView);
@property (nonatomic, strong) UIImage *placeholderImage;
@property (readwrite, assign) NSInteger selectedSection;
@property (nonatomic, strong) NSArray <KBSectionProtocol> *sections;
@property (nonatomic, strong) UITableView *tableView;
@property (readwrite, assign) BOOL useRoundedEdges;
@property (nonatomic, weak) UICollectionViewCell *focusedCollectionCell;
@property (nonatomic, strong) NSLayoutConstraint *headerTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *tableTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *tabBarTopConstraint;
@property (nonatomic, strong) UITabBar *tabBar;
@property (nonatomic, strong) NSArray <KBYTTab *> *tabDetails;

- (NSInteger)selectedTabIndex;
- (NSArray *)arrayForSection:(NSInteger)section;
- (KBYTChannelHeaderView *)headerview;
- (void)updateAutoScroll;
+ (BOOL)useRoundedEdges;
- (void)focusedCellIndex:(NSInteger)cellIndex inSection:(NSInteger)section inCollectionView:(UICollectionView *)collectionView;
- (void)handleSectionsUpdated;
- (BOOL)firstLoad;
- (void)handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)afterSetupTabBar;
@end

NS_ASSUME_NONNULL_END
