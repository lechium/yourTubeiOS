//
//  UIStackView+Helper.h
//  Ethereal
//
//  Created by Kevin Bradley on 7/16/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIStackView (Helper)
- (void)removeAllArrangedSubviews;
- (void)setArrangedViews:(NSArray *)views;
@end

NS_ASSUME_NONNULL_END
