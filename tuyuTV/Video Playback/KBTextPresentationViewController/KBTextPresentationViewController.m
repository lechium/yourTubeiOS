//
//  KBTextPresentationViewController.m
//  nitoTV4
//
//  Created by Kevin Bradley on 3/5/17.
//  Copyright © 2017 nito. All rights reserved.
//

#import "KBTextPresentationViewController.h"
#import "UIView+AL.h"

@interface KBTextPresentationViewController()



@end

@implementation KBTextPresentationViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    [self.view addSubview:blurView];
    [blurView autoPinEdgesToSuperviewEdges];
    [self.view addSubview:vibrancyEffectView];
    [vibrancyEffectView autoPinEdgesToSuperviewEdges];
    self.textView = [[UITextView alloc] initForAutoLayout];
    [vibrancyEffectView.contentView addSubview:self.textView];
    //self.textView.focusColorChange = NO;
    
    self.packageLogoView = [[UIImageView alloc] initForAutoLayout];
    self.packageLogoView.image = self.packageLogo;
    self.packageLogoView.contentMode = UIViewContentModeScaleAspectFit;
    //[vibrancyEffectView.contentView addSubview:self.packageLogoView];
    [self.view addSubview:self.packageLogoView];
    //[self.packageLogoView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:40];
    [self.packageLogoView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:40].active = true;
    [self.packageLogoView autoCenterHorizontallyInSuperview];
    //[self.packageLogoView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.packageLogoView autoConstrainToSize:CGSizeMake(222, 135)];
    
    
    [self.textView autoCenterHorizontallyInSuperview];
    //[self.textView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.packageLogoView withOffset:20];
    [self.textView.topAnchor constraintEqualToAnchor:self.packageLogoView.bottomAnchor constant:20].active = true;
    self.textView.userInteractionEnabled = YES;
    //self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.panGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    self.textView.scrollEnabled = YES;
    [self.textView.widthAnchor constraintEqualToAnchor:vibrancyEffectView.widthAnchor multiplier:0.7].active = true;
    //[self.textView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:vibrancyEffectView withMultiplier:0.7];
    //[self.textView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:vibrancyEffectView withMultiplier:0.8];
    [self.textView.heightAnchor constraintEqualToAnchor:vibrancyEffectView.heightAnchor multiplier:0.8].active = true;
    self.textView.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.textView.text = self.textValue;
    //self.label
    
}



- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    //[self.view printRecursiveDescription];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (UIView *)preferredFocusedView {
    return self.textView;
}
#pragma clang diagnostic pop
@end
