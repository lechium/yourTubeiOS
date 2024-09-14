//
//  KBDataItemCollectionViewCell.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 2/28/17.
//  Copyright © 2017 nito, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "MarqueeLabel.h"
@interface KBDataItemCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *bannerLabel;
@property (nonatomic, strong) UILabel *bannerDescription;
@property (nonatomic, strong) UILabel *bannerCategory;
@property (nonatomic, strong) UILabel *secondaryLabel;
@property (nonatomic, strong) NSLayoutConstraint *imageHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomlabelInset;

@end
