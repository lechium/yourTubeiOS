

#import "UIView+RecursiveFind.h"


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

- (void)printRecursiveDescription
{
    NSString *recursiveDesc = [self performSelector:@selector(recursiveDescription)];
    NSLog(@"%@", recursiveDesc);
}

- (void)removeAllSubviews
{
    for (UIView *view in self.subviews)
    {
        [view removeFromSuperview];
    }
}


@end
