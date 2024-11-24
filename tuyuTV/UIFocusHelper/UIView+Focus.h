//
//  UIView+Focus.h
//  UIFocusHelper
//
//  Created by Kevin Bradley on 12/1/23.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Focus)
- (NSArray <UIFocusGuide *>*)_helperFocusGuides;
- (void)visualizeFocusGuidesWithColor:(UIColor *)color;
- (void)visualizeFocusGuidesRemovingAfter:(NSTimeInterval)removeAfter;
- (void)visualizeFocusGuidesWithColor:(UIColor *)color removeAfter:(NSTimeInterval)removeAfter;
- (void)visualizeFocusGuides;
- (void)removeVisualizedFocusGuides;
@end

NS_ASSUME_NONNULL_END
