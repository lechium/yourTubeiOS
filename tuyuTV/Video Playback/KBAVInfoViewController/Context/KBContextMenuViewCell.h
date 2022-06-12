//
//  KBContextMenuViewCell.h
//  Ethereal
//
//  Created by kevinbradley on 2/23/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KBMenuElement.h"
NS_ASSUME_NONNULL_BEGIN

@class KBAction, KBContextMenuSection;

@interface KBContextMenuViewCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *label;
- (UIImageView *)leadingImageView;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (void)setAttributes:(KBMenuElementAttributes)attributes;
- (void)configureWithAction:(KBAction *)action section:(KBContextMenuSection *)section;
@end

NS_ASSUME_NONNULL_END
