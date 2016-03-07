//
//  YTTVFeaturedCollectionViewCell.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import "YTTVFeaturedCollectionViewCell.h"

@implementation YTTVFeaturedCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self commonInit];
    return self;
}

- (void)commonInit
{
    [self layoutIfNeeded];
    [self layoutSubviews];
    [self setNeedsDisplay];
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    if ([self isFocused])
    {
        self.featuredImage.adjustsImageWhenAncestorFocused = true;
    } else {
        self.featuredImage.adjustsImageWhenAncestorFocused = false;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

@end
