//
//  KBFocusHelper.h
//  UIFocusHelper
//
//  Created by Kevin Bradley on 1/15/24.
//

#import <Foundation/Foundation.h>
#import "UIFocusPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface KBFocusHelper : NSObject
+ (UIImage *)createFocusSnapshotFromViewController:(UIViewController *)viewController withHeading:(UIFocusHeading)focusHeading clipping:(BOOL)clipping;
+ (UIImage *)createFocusSnapshotFromViewController:(UIViewController *)viewController clipping:(BOOL)clipping;
@end

NS_ASSUME_NONNULL_END
