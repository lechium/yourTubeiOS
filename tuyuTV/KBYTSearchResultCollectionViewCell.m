//
//  KBYTSearchResultCollectionViewCell.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/7/16.
//
//

#import "KBYTSearchResultCollectionViewCell.h"

@implementation KBYTSearchResultCollectionViewCell
@synthesize title, image;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.image.adjustsImageWhenAncestorFocused = true;
    self.image.clipsToBounds = false;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    LOG_SELF;
    if ([self isFocused])
    {
        self.image.adjustsImageWhenAncestorFocused = true;
        self.title.hidden = false;
       
    } else {
        self.image.adjustsImageWhenAncestorFocused = false;
        self.title.hidden = true;
    }
}

@end
