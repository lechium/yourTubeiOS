//
//  KBDataItemCollectionViewCell.m
//  tvOSGridTest
//
//  Created by Kevin Bradley on 2/28/17.
//  Copyright © 2017 nito, LLC. All rights reserved.
//

#import "KBDataItemCollectionViewCell.h"
//#import "Defines.h"
#import "KBShelfViewController.h"

@implementation KBDataItemCollectionViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.secondaryLabel.text = @"";
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setupView];
    return self;
}

//"UIExtendedSRGBColorSpace 1 1 1 0.3"

- (UIColor *)labelColor {
    UIColor *theColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if(traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:1 green:1 blue: 1 alpha: 0.5];
        } else {
            return [UIColor blackColor];
        }
    }];
    return theColor;
}

- (UIColor *)secondaryLabelColor {
    UIColor *theColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if(traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:1 green:1 blue: 1 alpha: 0.3];
        } else {
            return [UIColor grayColor];
        }
    }];
    return theColor;
}


- (void)setupView {
    self.imageView = [[UIImageView alloc] initForAutoLayout];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.bannerLabel = [[UILabel alloc] initForAutoLayout];
    self.bannerCategory = [[UILabel alloc] initForAutoLayout];
    self.bannerDescription = [[UILabel alloc] initForAutoLayout];
    UIColor *bannerLightLabel = [UIColor whiteColor];
    UIColor *lightWhiteColor = [UIColor colorWithWhite:1 alpha:0.65];
    self.bannerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]; //UICTFontTextStyleTitle3 weight: normal, size 48.0
    self.bannerLabel.textColor = bannerLightLabel;
    self.bannerCategory.font = [UIFont boldSystemFontOfSize:23]; //SFUISemibold weight bold size 23. color: 0.188235 0.188235 0.2 0.45
    self.bannerCategory.textColor = lightWhiteColor;
    self.bannerDescription.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];//UICTFontTextStyleCallout size: 31 pt color: 0.188235, 0.188235, 0.2, 0.45
    self.bannerDescription.textColor = lightWhiteColor;
    self.bannerDescription.numberOfLines = 0;
    self.bannerDescription.lineBreakMode = NSLineBreakByWordWrapping;
    [self.bannerDescription autoSetDimension:NSLayoutAttributeWidth toSize:500];
    [self.bannerDescription autoSetDimension:NSLayoutAttributeHeight toSize:150 relation:NSLayoutRelationLessThanOrEqual];
    self.label = [[UILabel alloc] initForAutoLayout];
    self.label.enablesMarqueeWhenAncestorFocused = true;
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.label];
    [self.contentView addSubview:self.bannerCategory];
    [self.contentView addSubview:self.bannerDescription];
    [self.contentView addSubview:self.bannerLabel];
    CGFloat padding = 20;
    [self.bannerCategory.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:padding].active = true;
    [self.bannerCategory.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:40].active = true;
    [self.bannerLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:padding].active = true;
    [self.bannerDescription.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:padding].active = true;
    [self.bannerLabel.topAnchor constraintEqualToAnchor:self.bannerCategory.bottomAnchor constant:5].active = true;
    [self.bannerDescription.topAnchor constraintEqualToAnchor:self.bannerLabel.bottomAnchor constant:5].active = true;
    [self.imageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:UIRectEdgeBottom];
    self.imageView.image = [UIImage imageNamed:@"YTPlaceholder"];
    [self.label autoAlignAxisToSuperviewAxis:NSLayoutAttributeCenterX];
    self.bottomlabelInset = [self.label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:40];
    self.bottomlabelInset.active = true;
    self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    //DLog(@"labelfont: %@", self.label.font.fontName);
    self.label.text = @"";
    self.label.textAlignment = NSTextAlignmentCenter;
    self.secondaryLabel = [[UILabel alloc] initForAutoLayout];
    self.secondaryLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.secondaryLabel.text = @"";
    self.secondaryLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.secondaryLabel];
    [self.secondaryLabel autoAlignAxisToSuperviewAxis:NSLayoutAttributeCenterX];
    [self.secondaryLabel.topAnchor constraintEqualToAnchor:self.label.bottomAnchor constant:1].active = true;
    self.secondaryLabel.textColor = [UIColor grayColor];
    
    [self.label.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor multiplier:0.8].active = true;
    self.imageHeightConstraint = [self.imageView autoSetDimension:NSLayoutAttributeHeight toSize:320];
    self.imageView.adjustsImageWhenAncestorFocused =true;
    [self.bannerLabel shadowify];
    self.label.textColor = [self labelColor];
    self.secondaryLabel.textColor = [self secondaryLabelColor];
}

//price label color when dark mode: [UIColor colorWithRed:1 green:1 blue: 1 alpha: 0.3]
//dark mode unselected label color: "UIExtendedSRGBColorSpace 1 1 1 0.5"
//

- (void)updateOverlay {
    if (![KBShelfViewController useRoundedEdges]){
        return;
    }
    UIView *overlay = self.imageView.overlayContentView;
    if ([self isFocused]) {
        [overlay setCornerRadius:12.5 updatingShadowPath:true];
        overlay.layer.borderColor = [UIColor whiteColor].CGColor;
        overlay.layer.borderWidth = 5.0;
    } else {
        [overlay setCornerRadius:10.0 updatingShadowPath:true];
        overlay.layer.borderColor = [UIColor clearColor].CGColor;
        overlay.layer.borderWidth = 0.0;
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        
        if ([self isFocused]) {
            self.label.textColor = [UIColor whiteColor];
            self.secondaryLabel.textColor = [UIColor whiteColor];
            self.bottomlabelInset.constant = 70;
            if (self.label.text.length > 0){
                [self updateOverlay];
            }
        } else {
            if (self.label.text.length > 0) {
                [self updateOverlay];
            }
            self.label.textColor = [self labelColor];
            self.secondaryLabel.textColor = [self secondaryLabelColor];
            self.bottomlabelInset.constant = 50;
        }
    } completion:^{
        
    }];
    
}

@end
