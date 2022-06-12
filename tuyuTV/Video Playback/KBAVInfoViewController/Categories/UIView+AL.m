//
//  UIView+AL.m
//  Ethereal
//
//  Created by Kevin Bradley on 12/16/19.
//  Copyright © 2019 nito. All rights reserved.
//

#import "UIView+AL.h"

@implementation NSArray (al)

- (void)autoRemoveConstraints {
    if ([NSLayoutConstraint respondsToSelector:@selector(deactivateConstraints:)]) {
        [NSLayoutConstraint deactivateConstraints:self];
    }
}

@end

@implementation UIViewController (darkMode)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
#pragma clang diagnostic ignored "-Wunguarded-availability"
- (BOOL)darkMode {

    if ([[self traitCollection] respondsToSelector:@selector(userInterfaceStyle)]){
        return ([[self traitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark);
    } else {
        return false;
    }
    return false;
}
#pragma clang diagnostic pop
@end

@implementation UIView (al)

- (UIImageView *)findFirstImageViewWithTint:(UIColor *)tintColor {
    if ([self isMemberOfClass:[UIImageView class]]) { //member exclusively finds UIImageView
        //NSLog(@"found %@ color: %@ target tint: %@", self, self.tintColor, tintColor);
        if (self.tintColor == tintColor){
                return (UIImageView*)self;
            }
        }
    for (UIView *v in self.subviews) {
        UIImageView *theView = [v findFirstImageViewWithTint:tintColor];
        if (theView != nil){
            return theView;
        }
    }
    return nil;
}

- (UIView *)findFirstSubviewWithClass:(Class)theClass {
    if ([self isKindOfClass:theClass]) { //kind finds any kind of that class OR clases that inherit from it
            return self;
        }
    for (UIView *v in self.subviews) {
        UIView *theView = [v findFirstSubviewWithClass:theClass];
        if (theView != nil){
            return theView;
        }
    }
    return nil;
}

- (NSLayoutConstraint *)autoCenterHorizontallyInSuperview {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *constraint = [self.centerXAnchor constraintEqualToAnchor:self.superview.centerXAnchor];
    constraint.active = true;
    return constraint;
}

- (NSLayoutConstraint *)autoCenterVerticallyInSuperview {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *constraint = [self.centerYAnchor constraintEqualToAnchor:self.superview.centerYAnchor];
    constraint.active = true;
    return constraint;
}

- (NSArray <NSLayoutConstraint *> *)autoConstrainToSize:(CGSize)size {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *width = [self.widthAnchor constraintEqualToConstant:size.width];
    width.active = true;
    NSLayoutConstraint *height = [self.heightAnchor constraintEqualToConstant:size.height];
    height.active = true;
    return @[width, height];
}

- (NSArray <NSLayoutConstraint *> *)autoPinEdgesToSuperviewEdgesWithInsets:(UIEdgeInsets)inset {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *leadingConstraint = [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor constant:inset.left];
    leadingConstraint.active = true;
    NSLayoutConstraint *trailingConstraint = [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor constant:-inset.right];
    trailingConstraint.active = true;
    NSLayoutConstraint *topConstraint = [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor constant:inset.top];
    topConstraint.active = true;
    NSLayoutConstraint *bottomConstraint = [self.bottomAnchor constraintEqualToAnchor:self.superview.bottomAnchor constant:-inset.bottom];
    bottomConstraint.active = true;
    return @[leadingConstraint, trailingConstraint, topConstraint, bottomConstraint];
}

- (NSArray <NSLayoutConstraint *> *)autoPinEdgesToMargins {
    self.translatesAutoresizingMaskIntoConstraints = false;
     UILayoutGuide *viewMargins = self.layoutMarginsGuide;
    NSLayoutConstraint *width = [self.widthAnchor constraintEqualToAnchor:viewMargins.widthAnchor];
    width.active = true;
    NSLayoutConstraint *height = [self.heightAnchor constraintEqualToAnchor:viewMargins.heightAnchor];
    height.active = true;
    return @[width, height];
}

- (NSArray <NSLayoutConstraint *> *)autoPinEdgesToSuperviewEdges {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *leadingConstraint = [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor];
    leadingConstraint.active = true;
    NSLayoutConstraint *trailingConstraint = [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor];
    trailingConstraint.active = true;
    NSLayoutConstraint *topConstraint = [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor];
    topConstraint.active = true;
    NSLayoutConstraint *bottomConstraint = [self.bottomAnchor constraintEqualToAnchor:self.superview.bottomAnchor];
    bottomConstraint.active = true;
    return @[leadingConstraint, trailingConstraint, topConstraint, bottomConstraint];
}

- (void)removeAllSubviews {
    [[self subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       [obj removeFromSuperview];
    }];
}

- (NSArray <NSLayoutConstraint *> *)autoCenterInSuperview {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *yC = [self.centerYAnchor constraintEqualToAnchor:self.superview.centerYAnchor];
    yC.active = true;
    NSLayoutConstraint *xC = [self.centerXAnchor constraintEqualToAnchor:self.superview.centerXAnchor];
    xC.active = true;
    return @[xC, yC];
}

- (instancetype)initForAutoLayout {
    self = [self initWithFrame:CGRectZero];
    self.translatesAutoresizingMaskIntoConstraints = false;
    return self;
}

@end
