

#import "UIView+RecursiveFind.h"

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

@implementation UIView (RecursiveFind)



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

- (void)printRecursiveDescription {
    NSString *recursiveDesc = [self performSelector:@selector(recursiveDescription)];
    NSLog(@"%@", recursiveDesc);
}

- (void)removeAllSubviews {
    for (UIView *view in self.subviews)
    {
        [view removeFromSuperview];
    }
}


@end
