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
    self.title.alpha = 0;
}



- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    if ([self isFocused])
    {
        self.image.adjustsImageWhenAncestorFocused = true;
        self.title.alpha = 1;
    } else {
        self.image.adjustsImageWhenAncestorFocused = false;
        self.title.alpha = 0;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.title.alpha = 0;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
        self.title.alpha = 0;
}

@end
