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


- (id)initForAutoLayout
{
    self = [super initForAutoLayout];
    //[self setupView];
    return self;
}

- (void)setupView
{
    self.bannerImageView = [[UIImageView alloc] initForAutoLayout];
    [self addSubview:self.bannerImageView];
    self.bannerImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.bannerImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.bannerImageView autoSetDimension:ALDimensionHeight toSize:175];
    [self.bannerImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    self.authorLabel = [[UILabel alloc] initForAutoLayout];
    self.subscriberLabel = [[UILabel alloc] initForAutoLayout];
    [self addSubview:self.authorLabel];
    [self addSubview:self.subscriberLabel];
    [self.authorLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:99];
    [self.authorLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:27];
    [self.subscriberLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.authorLabel withOffset:9];
    [self.subscriberLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:27];
    [self.authorLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    [self.subscriberLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    self.authorLabel.textColor = [UIColor whiteColor];
    self.subscriberLabel.textColor = [UIColor whiteColor];
    //[self.subscriberLabel shadowify];
    //[self.authorLabel shadowify];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
