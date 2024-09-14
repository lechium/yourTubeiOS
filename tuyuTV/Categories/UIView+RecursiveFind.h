

#import <UIKit/UIKit.h>

@interface UICollectionViewCell (Jiggle)

@property (nonatomic) CGAffineTransform originalTransform;
- (void)startJiggling;
- (void)stopJiggling;
@end

@interface UIApplication (PrintRecursion)

- (void)printWindow;

@end

@interface UIView (RecursiveFind)

- (void)printRecursiveDescription;
- (void)removeAllSubviews;

@end
