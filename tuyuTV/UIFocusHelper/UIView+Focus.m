//
//  UIView+Focus.m
//  UIFocusHelper
//
//  Created by Kevin Bradley on 12/1/23.
//

#import "UIView+Focus.h"
#import "UIFocusGuide+Visualize.h"

@implementation UIView (Focus)

- (NSArray <UIFocusGuide *>*)_helperFocusGuides {
    NSArray <UIFocusGuide*>*layoutGuides = [self layoutGuides];
    NSPredicate *filterPred = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isMemberOfClass:UIFocusGuide.class];
    }];
    return [layoutGuides filteredArrayUsingPredicate:filterPred];
}

- (void)logFocusGuides {
    NSLog(@"focusGuides: %@", [self _helperFocusGuides]);
}

- (void)visualizeFocusGuides {
    [self visualizeFocusGuidesWithColor:[UIColor redColor] removeAfter:0];
}

- (void)removeVisualizedFocusGuides {
    NSArray <UIFocusGuide *>*focusGuides = [self _helperFocusGuides];
    [focusGuides enumerateObjectsUsingBlock:^(UIFocusGuide * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[obj visualizedView] removeFromSuperview]; //should be a no-op if none exists
        [obj setVisualizedView:nil];
    }];
}

- (void)visualizeFocusGuidesWithColor:(UIColor *)color {
    [self visualizeFocusGuidesWithColor:color removeAfter:0];
}

- (void)visualizeFocusGuidesRemovingAfter:(NSTimeInterval)removeAfter {
    [self visualizeFocusGuidesWithColor:[UIColor redColor] removeAfter:removeAfter];
}

- (void)visualizeFocusGuidesWithColor:(UIColor *)color removeAfter:(NSTimeInterval)removeAfter {
    NSArray <UIFocusGuide *>*focusGuides = [self _helperFocusGuides];
    __block NSInteger startingTag = 420;
    [focusGuides enumerateObjectsUsingBlock:^(UIFocusGuide * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *view = [obj visualizeWithColor:color];
        view.tag = startingTag;
        startingTag++;
    }];
    if (removeAfter > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(removeAfter * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeVisualizedFocusGuides];
        });
    }
}

@end
