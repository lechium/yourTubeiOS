

#import <UIKit/UIKit.h>

@interface UIApplication (PrintRecursion)

- (void)printWindow;

@end

@interface UIView (RecursiveFind)

- (UIView *)findFirstSubviewWithClass:(Class)theClass;
- (void)printRecursiveDescription;
- (void)removeAllSubviews;

@end
