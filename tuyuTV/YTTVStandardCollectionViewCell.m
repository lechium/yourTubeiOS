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
    self.title.alpha = 1;
}



- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
       //    NSLog(@"overLayInfo frame: %@", NSStringFromCGRect(self.overlayView.frame));
    //{{160, 30}, {160, 222}}
    if ([self isFocused])
    {
        self.image.adjustsImageWhenAncestorFocused = true;
        CGRect frame = self.overlayView.frame;
        frame.size.height = 300;
        frame.origin.y = 0;
        frame.size.width = 250;
        self.overlayView.frame = frame;
        self.title.alpha = 1;
    } else {
        CGRect frame = self.overlayView.frame;
        frame.size.height = 240;
        frame.origin.y = 30;
        frame.size.width = 160;
        self.overlayView.frame = frame;
        self.image.adjustsImageWhenAncestorFocused = false;
        self.title.alpha = 1;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.title.alpha = 1;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
        self.title.alpha = 1;
}

@end
