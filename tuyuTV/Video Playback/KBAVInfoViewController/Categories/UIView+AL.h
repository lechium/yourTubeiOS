//
//  UIView+AL.h
//  Ethereal
//
//  Created by Kevin Bradley on 12/16/19.
//  Copyright © 2019 nito. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (al)
- (void)autoRemoveConstraints;
@end

@interface UIViewController (darkMode)
- (BOOL)darkMode;
@end

@interface UIView (AL)
- (UIImageView *)findFirstImageViewWithTint:(UIColor *)tintColor;
- (UIView *)findFirstSubviewWithClass:(Class)theClass;
- (id)initForAutoLayout;
- (NSArray <NSLayoutConstraint *> *)autoPinEdgesToMargins;
- (NSArray <NSLayoutConstraint *> *)autoCenterInSuperview;
- (NSLayoutConstraint *)autoCenterHorizontallyInSuperview;
- (NSLayoutConstraint *)autoCenterVerticallyInSuperview;
- (NSArray <NSLayoutConstraint *> *)autoPinEdgesToSuperviewEdges;
- (NSArray <NSLayoutConstraint *> *)autoPinEdgesToSuperviewEdgesWithInsets:(UIEdgeInsets)inset;
- (NSArray <NSLayoutConstraint *> *)autoConstrainToSize:(CGSize)size;
- (void)removeAllSubviews;
@end

NS_ASSUME_NONNULL_END
