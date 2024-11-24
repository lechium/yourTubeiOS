//
//  UIFocusGuide+Visualize.m
//  UIFocusHelper
//
//  Created by Kevin Bradley on 12/1/23.
//

#import "UIFocusGuide+Visualize.h"

@implementation UIFocusGuide (Visualize)

- (void)setVisualizedView:(nullable UIView *)view {
    objc_setAssociatedObject(self, @selector(visualizedView), view, OBJC_ASSOCIATION_RETAIN);
}

- (nullable UIView *)visualizedView {
    return objc_getAssociatedObject(self, @selector(visualizedView));
}

- (UIView *)visualizeWithColor:(UIColor *)color {
    UIView *view = [UIView new];
    view.frame = self.layoutFrame;
    view.backgroundColor = [UIColor redColor];
    [self.owningView addSubview:view];
    if ([self.identifier length] > 0 ){
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont boldSystemFontOfSize:14];
        label.text = self.identifier;
        label.backgroundColor = [UIColor blackColor];
        [label sizeToFit];
        [view addSubview:label];
    }
    UIView *visualizedTest = [self visualizedView];
    if (visualizedTest){
        [visualizedTest removeFromSuperview];
    }
    [self setVisualizedView:view];
    return view;
}

- (UIView *)visualize {
    return [self visualizeWithColor:[UIColor redColor]];
}

@end
