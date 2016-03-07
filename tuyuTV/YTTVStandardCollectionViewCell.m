//
//  YTTVStandardCollectionViewCell.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import "YTTVStandardCollectionViewCell.h"

@implementation YTTVStandardCollectionViewCell

@synthesize title, image;

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
        self.image.adjustsImageWhenAncestorFocused = true;
        self.title.hidden = false;
    } else {
        self.image.adjustsImageWhenAncestorFocused = false;
        self.title.hidden = true;
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
