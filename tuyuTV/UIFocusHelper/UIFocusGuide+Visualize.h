//
//  UIFocusGuide+Visualize.h
//  UIFocusHelper
//
//  Created by Kevin Bradley on 12/1/23.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFocusGuide (Visualize)
- (UIView *)visualizeWithColor:(UIColor *)color;
- (UIView *)visualize;
- (nullable UIView *)visualizedView;
- (void)setVisualizedView:(nullable UIView *)view;
@end

NS_ASSUME_NONNULL_END
