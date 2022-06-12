//
//  KBMoreButton.h
//  TvOSMoreButtonObjC
//
//  Created by Kevin Bradley on 11/11/18.
//  Copyright © 2018 Kevin Bradley All rights reserved.
//

#import <UIKit/UIKit.h>


@interface KBMoreButton : UIView

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSString *ellipsesString;
@property (nonatomic, strong) NSString *trailingText;
@property (nonatomic, strong) UIColor *trailingTextColor;
@property (nonatomic, strong) UIFont *trailingTextFont;
@property (readwrite, assign) CGFloat pressAnimationDuration;
@property (readwrite, assign) CGFloat labelMargin;
@property (readwrite, assign) CGFloat cornerRadius;
@property (readwrite, assign) CGFloat focusedScaleFactor;
@property (readwrite, assign) CGFloat shadowRadius;
@property (nonatomic, assign) CGColorRef shadowColor; //assign.. weird.
@property (readwrite, assign) CGSize focusedShadowOffset;
@property (readwrite, assign) CGFloat focusedShadowOpacity;
@property (readwrite, assign) CGFloat focusedViewAlpha;
@property (nonatomic, copy) void (^buttonWasPressed)(NSString *text);
@property (nonatomic, copy) void (^focusableUpdated)(BOOL canFocus);

- (BOOL)canFocus;
- (NSTextAlignment)textAlignment;
- (void)setTextAlignment:(NSTextAlignment)alignment;


@end
