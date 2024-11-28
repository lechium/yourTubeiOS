//
//  UIViewController+FocusHelper.m
//  UIFocusHelper
//
//  Created by Kevin Bradley on 1/21/24.
//

#import "UIViewController+FocusHelper.h"
#import "KBFocusHelper.h"

@implementation UIViewController (FocusHelper)

- (void)showFocusDebugAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Create focus snapshot" message:@"Choose the direction you want the focus snapshot to calculate for, none with generate a generic focus image without any cropped focus areas." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *leftAction = [UIAlertAction actionWithTitle:@"Left" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performActionWithHeading:UIFocusHeadingLeft];
    }];
    UIAlertAction *rightAction = [UIAlertAction actionWithTitle:@"Right" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performActionWithHeading:UIFocusHeadingRight];
    }];
    UIAlertAction *upAction = [UIAlertAction actionWithTitle:@"Up" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performActionWithHeading:UIFocusHeadingUp];
    }];
    UIAlertAction *downAction = [UIAlertAction actionWithTitle:@"Down" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performActionWithHeading:UIFocusHeadingDown];
    }];
    UIAlertAction *noneAction = [UIAlertAction actionWithTitle:@"None" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performActionWithHeading:UIFocusHeadingNone];
    }];
    [alertController addAction:noneAction];
    [alertController addAction:leftAction];
    [alertController addAction:rightAction];
    [alertController addAction:upAction];
    [alertController addAction:downAction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertController animated:true completion:^{
            
        }];
    });
}

+ (UIViewController *)imageViewControllerWithImage:(UIImage *)image {
    UIViewController *vc = [UIViewController new];
    UIImageView *imageView = [UIImageView new];
    imageView.translatesAutoresizingMaskIntoConstraints = false;
    [vc.view addSubview:imageView];
    imageView.image = image;
    [imageView.topAnchor constraintEqualToAnchor:vc.view.topAnchor].active = true;
    [imageView.bottomAnchor constraintEqualToAnchor:vc.view.bottomAnchor].active = true;
    [imageView.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor].active = true;
    [imageView.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor].active = true;
    
    return vc;
}

- (void)performActionWithHeading:(UIFocusHeading)heading {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL isClipping = true;
        if (heading == UIFocusHeadingNone) {
            isClipping = false;
        }
        UIImage *focusImage = [KBFocusHelper createFocusSnapshotFromViewController:self withHeading:heading clipping:isClipping];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *imageVC = [UIViewController imageViewControllerWithImage:focusImage];
            [self presentViewController:imageVC animated:true completion:nil];
        });
    });
}
@end
