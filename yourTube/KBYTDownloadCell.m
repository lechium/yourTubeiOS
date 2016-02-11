//
//  KBYTDownloadCell.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/10/16.
//
//

#import "KBYTDownloadCell.h"

@implementation KBYTDownloadCell

@synthesize downloading, progressView, durationLabel, duration;

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    LOG_SELF;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

/**
 
 Probably not the best way to handle keeping images all the same size, but it works, and works
 smoothly, so thats all that matters.
 
 Aside from that there is some hackiness to the way the marquee labels are layed out, the text is
 initially set in the normal textLabel and detailLabels, that layout work is leveraged onto
 the marquee labels for positioning and the marquee labels overlay the same frames as the
 original labels. it works and looks good. so who cares :) This is also where
 download progress is managed, can't think of another way to handle all of this.
 
 */

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(0,0,133,100);
    self.imageView.backgroundColor = [UIColor blackColor];
    float limgW =  self.imageView.image.size.width;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if(limgW > 0) {
        
        CGFloat textFieldWidth = self.frame.size.width - 148 - 10;
        //recreate the marquee labels each time, probably not efficient but it works smoothly.
        if ([self marqueeTextLabel] != nil)
        {
            [[self marqueeTextLabel] removeFromSuperview];
        }
        if ([self marqueeDetailTextLabel] != nil)
        {
            [[self marqueeDetailTextLabel] removeFromSuperview];
        }
        
        if ([self durationLabel] != nil)
        {
            [[self durationLabel] removeFromSuperview];
        }
        
        if ([self viewsLabel] != nil)
        {
            [[self viewsLabel] removeFromSuperview];
        }
        
        self.textLabel.frame = CGRectMake(148 ,self.textLabel.frame.origin.y-10,textFieldWidth,self.textLabel.frame.size.height);
        self.marqueeTextLabel = [[MarqueeLabel alloc] initWithFrame:self.textLabel.frame];
        self.marqueeTextLabel.font = self.textLabel.font;
        self.marqueeTextLabel.textColor = self.textLabel.textColor;
        self.marqueeTextLabel.text = self.textLabel.text;
        self.textLabel.hidden = true;
        
        CGRect durationFrame = CGRectMake(100, self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height+2, 25, self.detailTextLabel.frame.size.height);
        self.durationLabel = [[UILabel alloc] initWithFrame:durationFrame];
        //NSLog(@"font: %@", self.detailTextLabel.font);
        UIFont *theFont = [UIFont systemFontOfSize:14];
        self.durationLabel.font = self.detailTextLabel.font;
        self.durationLabel.textColor = [UIColor whiteColor];
        self.durationLabel.backgroundColor = [UIColor blackColor];
        self.durationLabel.text = self.duration;
        [[self contentView] addSubview:self.durationLabel];
      
        CGRect viewsFrame = CGRectMake(148, self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height+2, 100, self.detailTextLabel.frame.size.height);
        self.viewsLabel = [[UILabel alloc] initWithFrame:viewsFrame];
        self.viewsLabel.font = self.detailTextLabel.font;
        self.viewsLabel.textColor = [UIColor blackColor];
        self.viewsLabel.text = self.views;
        [self.viewsLabel sizeToFit];
        [[self contentView] addSubview:self.viewsLabel];
        
        
        self.detailTextLabel.frame = CGRectMake(148,self.detailTextLabel.frame.origin.y-5,textFieldWidth,self.detailTextLabel.frame.size.height);
        self.marqueeDetailTextLabel = [[MarqueeLabel alloc] initWithFrame:self.detailTextLabel.frame];
        self.marqueeDetailTextLabel.font = theFont;//self.detailTextLabel.font;
        self.marqueeDetailTextLabel.textColor = [UIColor redColor];//self.detailTextLabel.textColor;
        self.marqueeDetailTextLabel.text = self.detailTextLabel.text;
        [[self contentView] addSubview:self.marqueeDetailTextLabel];
        [[self contentView] addSubview:self.marqueeTextLabel];
        self.marqueeDetailTextLabel.frame =  self.detailTextLabel.frame;
        self.detailTextLabel.hidden = true;
        
        if ([self progressView] != nil)
        {
            [[self progressView] removeFromSuperview];
        }
        
        if (self.downloading == true)
        {
            self.progressView = [[JGProgressView alloc] initWithFrame:CGRectMake(148, self.detailTextLabel.frame.origin.y + self.textLabel.frame.size.height + 5, textFieldWidth, 2)];
            [[self contentView] addSubview:self.progressView];
        }
    }
    
    
    
}

@end
