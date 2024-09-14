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

- (NSLayoutConstraint *)autoAlignAxisToSuperviewAxis:(NSLayoutAttribute)axis {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *constraint = nil;
    switch(axis) {
        case NSLayoutAttributeCenterY:
            constraint = [self.centerYAnchor constraintEqualToAnchor:self.superview.centerYAnchor];
            break;
            
        case NSLayoutAttributeCenterX:
            constraint = [self.centerXAnchor constraintEqualToAnchor:self.superview.centerXAnchor];
            break;
            
        default:
            break;
    }
    constraint.active = true;
    return constraint;
}

- (NSLayoutConstraint *)autoCenterHorizontallyInSuperview {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *constraint = [self.centerYAnchor constraintEqualToAnchor:self.superview.centerYAnchor];
    constraint.active = true;
    return constraint;
}

- (NSLayoutConstraint *)autoCenterVerticallyInSuperview {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *constraint = [self.centerXAnchor constraintEqualToAnchor:self.superview.centerXAnchor];
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

- (NSArray <NSLayoutConstraint *> *)autoPinEdgesToSuperviewEdgesWithInsets:(UIEdgeInsets)inset excludingEdge:(UIRectEdge)edge {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSMutableArray *constraints = [NSMutableArray new];
    if (edge != UIRectEdgeLeft) {
        NSLayoutConstraint *leadingConstraint = [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor constant:inset.left];
        leadingConstraint.active = true;
        [constraints addObject:leadingConstraint];
    }
    if (edge != UIRectEdgeRight) {
        NSLayoutConstraint *trailingConstraint = [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor constant:-inset.right];
        trailingConstraint.active = true;
        [constraints addObject:trailingConstraint];
    }
    if (edge != UIRectEdgeTop) {
        NSLayoutConstraint *topConstraint = [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor constant:inset.top];
        topConstraint.active = true;
        [constraints addObject:topConstraint];
    }
    if (edge != UIRectEdgeBottom) {
        NSLayoutConstraint *bottomConstraint = [self.bottomAnchor constraintEqualToAnchor:self.superview.bottomAnchor constant:-inset.bottom];
        bottomConstraint.active = true;
        [constraints addObject:bottomConstraint];
    }
    return constraints;
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
    NSLayoutConstraint *leadingConstraint = [self.leadingAnchor constraintEqualToAnchor:viewMargins.leadingAnchor];
    NSLayoutConstraint *trailingConstraint = [self.trailingAnchor constraintEqualToAnchor:viewMargins.trailingAnchor];
    NSLayoutConstraint *topConstraint = [self.topAnchor constraintEqualToAnchor:viewMargins.topAnchor];
    NSLayoutConstraint *bottomConstraint = [self.bottomAnchor constraintEqualToAnchor:viewMargins.bottomAnchor];
    leadingConstraint.active = true;
    trailingConstraint.active = true;
    topConstraint.active = true;
    bottomConstraint.active = true;
    return @[leadingConstraint, trailingConstraint, topConstraint, bottomConstraint];
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

- (NSArray <NSLayoutConstraint *> *)autoCenterInSuperview {
    self.translatesAutoresizingMaskIntoConstraints = false;
    NSLayoutConstraint *yC = [self.centerYAnchor constraintEqualToAnchor:self.superview.centerYAnchor];
    yC.active = true;
    NSLayoutConstraint *xC = [self.centerXAnchor constraintEqualToAnchor:self.superview.centerXAnchor];
    xC.active = true;
    return @[xC, yC];
}

- (NSLayoutConstraint *)autoSetDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size {
    NSLayoutConstraint *constraint = nil;
    switch (dimension) {
        case NSLayoutAttributeWidth:
            constraint = [self.widthAnchor constraintEqualToConstant:size];
            break;
            
        case NSLayoutAttributeHeight:
            constraint = [self.heightAnchor constraintEqualToConstant:size];
            
        default:
            break;
    }
    constraint.active = true;
    return constraint;
}

- (NSLayoutConstraint *)autoSetDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size relation:(NSLayoutRelation)relation {
    NSLayoutConstraint *constraint = nil;
    SEL selector = @selector(constraintEqualToConstant:);
    
    switch (relation) {
        case NSLayoutRelationEqual:
            selector =  @selector(constraintEqualToConstant:);
            break;
        case NSLayoutRelationGreaterThanOrEqual:
            selector = @selector(constraintGreaterThanOrEqualToConstant:);
            break;
            
        case NSLayoutRelationLessThanOrEqual:
            selector = @selector(constraintLessThanOrEqualToConstant:);
            break;
    }
    //
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    switch (dimension) {
        case NSLayoutAttributeWidth:
            constraint = [self.widthAnchor performSelector:selector withObject:@(size)];
            break;
            
        case NSLayoutAttributeHeight:
            constraint = [self.heightAnchor performSelector:selector withObject:@(size)];
            
        default:
            break;
    }
#pragma clang diagnostic pop
    constraint.active = true;
    return constraint;
}


- (instancetype)initForAutoLayout {
    self = [self initWithFrame:CGRectZero];
    self.translatesAutoresizingMaskIntoConstraints = false;
    return self;
}

- (void)setCornerRadius:(CGFloat)radius updatingShadowPath:(BOOL)updatingShadowPath {
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = radius > 0;
    if (updatingShadowPath) {
        self.layer.shadowPath = radius > 0 ? [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius].CGPath : nil;
    }
}

@end
