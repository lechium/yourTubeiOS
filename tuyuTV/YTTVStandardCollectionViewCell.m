//
//  YTTVStandardCollectionViewCell.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import "YTTVStandardCollectionViewCell.h"

@implementation YTTVStandardCollectionViewCell

@synthesize title, image, durationLabel;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self commonInit];
    return self;
}

- (void)commonInit {
    [self layoutIfNeeded];
    [self layoutSubviews];
    [self setNeedsDisplay];
    self.title.holdScrolling = true;
    self.title.alpha = 1;
    DLog(@"dl: %@", self.durationLabel);
}



- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    //    NSLog(@"overLayInfo frame: %@", NSStringFromCGRect(self.overlayView.frame));
    //{{160, 30}, {160, 222}}
    if ([self isFocused]) {
        
        self.image.adjustsImageWhenAncestorFocused = true;
        CGRect frame = self.overlayView.frame;
        frame.size.height = 300;
        frame.origin.y = 0;
        frame.size.width = 250;
        self.overlayView.frame = frame;
        self.title.alpha = 1;
        self.title.holdScrolling = false;
        [self.title restartLabel];
        self.durationTrailingConstraint.constant = 0;
        self.durationBottomConstraint.constant = -10;
    } else {
        CGRect frame = self.overlayView.frame;
        frame.size.height = 240;
        frame.origin.y = 30;
        frame.size.width = 160;
        self.overlayView.frame = frame;
        self.image.adjustsImageWhenAncestorFocused = false;
        self.title.alpha = 1;
        self.title.holdScrolling = true;
        [self.title shutdownLabel];
        self.durationTrailingConstraint.constant = 10;
        self.durationBottomConstraint.constant = -33;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.title shutdownLabel];
    self.title.alpha = 1;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.title.alpha = 1;
    self.title.holdScrolling = true;
}

@end
