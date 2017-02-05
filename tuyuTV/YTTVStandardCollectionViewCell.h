//
//  YTTVStandardCollectionViewCell.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import <UIKit/UIKit.h>
#import "MarqueeLabel.h"

@interface YTTVStandardCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *image;
@property (nonatomic, weak) IBOutlet MarqueeLabel *title;
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UILabel *overlayInfo;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *durationTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *durationBottomConstraint;
@end
