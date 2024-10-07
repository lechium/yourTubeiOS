//
//  KBTableViewCell.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 2/28/17.
//  Copyright © 2017 nito, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KBProtocols.h"
#import "KBSection.h"

static NSString *CollectionViewCellIdentifier = @"CollectionViewCellIdentifier";

@interface KBTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *trayTitleLabel;
@property (nonatomic, strong) KBSection *section;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (readwrite, assign) ChannelDisplayType channelDisplayType;

- (NSIndexPath *)focusedIndexPath;
- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching>)dataSourceDelegate section:(NSInteger)section;
- (void)goToOne;
@end
