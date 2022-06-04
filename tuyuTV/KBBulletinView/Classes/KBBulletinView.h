//
//  KBBulletinView.h
//  Ethereal
//
//  Created by Kevin Bradley on 2/1/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, KBBulletinViewType) {
    
    KBBulletinViewTypeDefault,
    KBBulletinViewTypeBottom
};

@interface KBBulletinView : UIView

@property (nonatomic, strong) NSString *bulletinTitle;
@property (nonatomic, strong) NSString *bulletinDescription;
@property (nonatomic, strong) UIImage *bulletinImage;
@property (readwrite, assign) KBBulletinViewType bulletinType;

+ (instancetype)bulletinWithTitle:(NSString *)title description:(NSString *_Nullable)desc image:(UIImage * _Nullable)image type:(KBBulletinViewType)type;
+ (instancetype)bulletinWithTitle:(NSString *)title description:(NSString *_Nullable)desc image:(UIImage * _Nullable)image;
- (instancetype)initWithTitle:(NSString *)title description:(NSString *_Nullable)desc image:(UIImage * _Nullable )image type:(KBBulletinViewType)type;
- (void)showForTime:(CGFloat)duration;
- (void)showFromController:(UIViewController *_Nullable)controller forTime:(CGFloat)duration;
- (void)hideView;
@end

NS_ASSUME_NONNULL_END
