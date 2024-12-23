//
//  KBYTChannelHeaderView.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/26/17.
//
//

#import "KBYTChannelHeaderView.h"
#import "KBYourTube.h"

@interface KBYTChannelHeaderView ()




@end


@implementation KBYTChannelHeaderView


- (id)initForAutoLayout {
    self = [super initForAutoLayout];
    //[self setupView];
    return self;
}

- (void)setupView
{
    self.bannerImageView = [[UIImageView alloc] initForAutoLayout];
    self.avatarImageView = [[UIImageView alloc] initForAutoLayout];
    [self addSubview:self.bannerImageView];
    self.bannerImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.avatarImageView.widthAnchor constraintLessThanOrEqualToConstant:176].active = true;
    [self.avatarImageView.heightAnchor constraintLessThanOrEqualToConstant:176].active = true;
    [self.bannerImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.bannerImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    self.bannerImageView.clipsToBounds = true;
    UIView *bannerOverlay = [[UIView alloc] initForAutoLayout];
    [self.bannerImageView addSubview:bannerOverlay];
    [bannerOverlay autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-80];
    [bannerOverlay autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    bannerOverlay.clipsToBounds = false;
    [bannerOverlay.heightAnchor constraintEqualToConstant:340].active = true;
    bannerOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.20];
    self.authorLabel = [[UILabel alloc] initForAutoLayout];
    self.subscriberLabel = [[UILabel alloc] initForAutoLayout];
    self.subscriberLabel.numberOfLines = 0;
    self.subscriberLabel.lineBreakMode = NSLineBreakByWordWrapping;
    //[self.bannerImageView addSubview:self.authorLabel];
    //[self.bannerImageView addSubview:self.subscriberLabel];
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.authorLabel, self.subscriberLabel]];
    UIStackView *horizontalStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.avatarImageView, stackView]];
    horizontalStackView.axis = UILayoutConstraintAxisHorizontal;
    horizontalStackView.alignment = UIStackViewAlignmentCenter;
    stackView.axis = UILayoutConstraintAxisVertical;
    horizontalStackView.spacing = 15.0;
    [self.bannerImageView addSubview:horizontalStackView];
    [horizontalStackView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:40];
    [horizontalStackView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:20];
    //stackView.backgroundColor = [UIColor redColor];
    //[self.authorLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:99];
    //[self.authorLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:40];
    //[self.subscriberLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.authorLabel withOffset:9];
    //[self.subscriberLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:40];
    [self.authorLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    [self.subscriberLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    self.authorLabel.textColor = [UIColor whiteColor];
    self.subscriberLabel.textColor = [UIColor whiteColor];
    [self.subscriberLabel shadowify];
    [self.authorLabel shadowify];
    /*
    self.subButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.subButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.bannerImageView addSubview:self.subButton];
    [self.subButton autoCenterHorizontallyInSuperview];
    [self.subButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:25.0];
    [self.subButton setTitle:@"Subscribe" forState:UIControlStateNormal];
    UIFocusGuide *focusGuideTop = [[UIFocusGuide alloc] init];
    [self.bannerImageView addLayoutGuide:focusGuideTop];
    [focusGuideTop.widthAnchor constraintEqualToAnchor:self.bannerImageView.widthAnchor].active = true;
    [focusGuideTop.heightAnchor constraintEqualToConstant:1].active = true;
    [focusGuideTop.bottomAnchor constraintEqualToAnchor:self.bannerImageView.bottomAnchor].active = true;
    [focusGuideTop.leadingAnchor constraintEqualToAnchor:self.bannerImageView.leadingAnchor].active = true;
    [focusGuideTop.trailingAnchor constraintEqualToAnchor:self.bannerImageView.trailingAnchor].active = true;
    focusGuideTop.preferredFocusEnvironments = @[self.subButton];
    [self.subButton addTarget:self action:@selector(subButtonPressed:) forControlEvents:UIControlEventPrimaryActionTriggered];
     */
}

- (void)subButtonPressed:(id)sender {
    LOG_SELF;
    if (self.subToggledBlock) {
        self.subToggledBlock();
    }
}

- (void)updateRounding {
    if (self.avatarImageView.image) {
        TLog(@"self.avatarImageView.bounds.size.width: %f imageWidth: %f", self.avatarImageView.bounds.size.width, self.avatarImageView.image.size.width);
        self.avatarImageView.layer.cornerRadius  = self.avatarImageView.bounds.size.width / 2;
        self.avatarImageView.layer.masksToBounds = YES;
    }
}
/*
- (void)layoutSubviews {
    LOG_SELF;
    [super layoutSubviews];
    if (self.avatarImageView.image) {
        self.avatarImageView.layer.cornerRadius  = self.avatarImageView.bounds.size.width / 2;
        self.avatarImageView.layer.masksToBounds = YES;
    }
}
*/
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
