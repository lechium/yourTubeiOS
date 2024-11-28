//
//  UIView+UIView_RecursiveFind.m
//  tvOSGridTest
//
//  Created by Kevin Bradley on 3/12/16.
//  Copyright © 2016 nito. All rights reserved.
//

#import "UIView+RecursiveFind.h"
//#import "Defines.h"

@implementation UICollectionViewCell (Jiggle)

- (void)setOriginalTransform:(CGAffineTransform)originalTransform {
    NSValue *value = [NSValue valueWithCGAffineTransform:originalTransform];
    [self associateValue:value withKey:@selector(originalTransform)];
}

- (CGAffineTransform)originalTransform {
    NSValue *value = [self associatedValueForKey:@selector(originalTransform)];
    return [value CGAffineTransformValue];
}

- (void)stopJiggling {
    [CATransaction begin];
    [self.layer removeAllAnimations];
    [self.contentView.layer removeAllAnimations];
    [CATransaction commit];
}

- (void)startJiggling {
    //startJiggling
    [self setOriginalTransform:self.transform];
    int count = 1;
    CGAffineTransform leftWobble = CGAffineTransformMakeRotation(degreesToRadians( kAnimationRotateDeg * (count%2 ? +1 : -1 ) ));
    CGAffineTransform rightWobble = CGAffineTransformMakeRotation(degreesToRadians( kAnimationRotateDeg * (count%2 ? -1 : +1 ) ));
    CGAffineTransform moveTransform = CGAffineTransformTranslate(rightWobble, -kAnimationTranslateX, -kAnimationTranslateY);
    CGAffineTransform conCatTransform = CGAffineTransformConcat(rightWobble, moveTransform);
    
    self.transform = leftWobble;  // starting point
    
    [UIView animateWithDuration:0.1
                          delay:(count * 0.08)
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{ self.transform = conCatTransform; }
                     completion:nil];
}

@end

@implementation UIApplication (PrintRecursion)

- (void)printWindow {
    [self.keyWindow.rootViewController.view printRecursiveDescription];
}

@end


@implementation NSArray (al)

- (void)autoRemoveConstraints {
    if ([NSLayoutConstraint respondsToSelector:@selector(deactivateConstraints:)]) {
        [NSLayoutConstraint deactivateConstraints:self];
    }
}

@end

@implementation UIImage (Render)

- (CGFloat)aspectRatio {
    return self.size.width/self.size.height;
}

- (UIImage *)roundedBorderImage:(CGFloat)cornerRadius borderColor:(UIColor *)color borderWidth:(CGFloat)width {
    __block UIImage *image = [UIImage renderedImage:self.size render:^(CGRect rect, CGContextRef context) {
        UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
        [roundedRect addClip];
        CGContextDrawImage(context, rect, self.CGImage);
        if (color) {
            [color setStroke];
            roundedRect.lineWidth = 2 * width;
            [roundedRect stroke];
        }
    }];
    return image;
}

+ (UIImage *)renderedImage:(CGSize)size render:(void(^)(CGRect rect, CGContextRef context))renderBlock {
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    __block UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        CGContextTranslateCTM(rendererContext.CGContext, 0, bounds.size.height);
        CGContextScaleCTM(rendererContext.CGContext, 1, -1);
        renderBlock(bounds, rendererContext.CGContext);
    }];
    return image;
}
@end

//-Wincomplete-implementation
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation UIView (RecursiveFind)
#pragma clang diagnostic pop

- (BOOL)darkMode {
    
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark){
        return TRUE;
    }
    return FALSE;
}



- (UIView *)findFirstSubviewWithClass:(Class)theClass {
    
    if ([self isKindOfClass:theClass]) {
            return self;
        }
    
    for (UIView *v in self.subviews) {
        UIView *theView = [v findFirstSubviewWithClass:theClass];
        if (theView != nil)
        {
            return theView;
        }
    }
    return nil;
}
- (void)printAutolayoutTrace
{
    // NSString *recursiveDesc = [self performSelector:@selector(recursiveDescription)];
    //DLog(@"%@", recursiveDesc);
#if DEBUG
    NSString *trace = [self _recursiveAutolayoutTraceAtLevel:0];
    DLog(@"%@", trace);
#endif
}


- (void)printRecursiveDescription
{
//#if DEBUG

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSString *recursiveDesc = [self performSelector:@selector(recursiveDescription)];
#pragma clang diagnostic pop
    DLog(@"%@", recursiveDesc);
//#else
  //  DLog(@"BUILT FOR RELEASE, NO SOUP FOR YOU");
//#endif
}

- (void)removeAllSubviews
{
    for (UIView *view in self.subviews)
    {
        [view removeFromSuperview];
    }
}

@end
