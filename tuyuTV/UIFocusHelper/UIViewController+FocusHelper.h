//
//  UIViewController+FocusHelper.h
//  UIFocusHelper
//
//  Created by Kevin Bradley on 1/21/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (FocusHelper)
- (void)showFocusDebugAlertController;
- (void)performActionWithHeading:(UIFocusHeading)heading;
+ (UIViewController *)imageViewControllerWithImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
