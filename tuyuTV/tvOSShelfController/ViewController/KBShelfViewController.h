//
//  KBFeaturedViewController.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 2/28/17.
//  Copyright © 2017 nito, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KBProtocols.h"

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

//UITableViewController
@interface KBShelfViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSourcePrefetching>

//@property (nonatomic, copy, nullability) returnType (^blockName)(parameterTypes);
@property (nonatomic, copy, nullable) void (^itemSelectedBlock)(KBModelItem *item, BOOL longPress);
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) NSArray <KBSection *> *sections;
@property (nonatomic, strong) UITableView *tableView;
@property (readwrite, assign) BOOL useRoundedEdges;

- (void)updateAutoScroll;
+ (BOOL)useRoundedEdges;
@end

NS_ASSUME_NONNULL_END
