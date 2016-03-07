//
//  KBYTSearchResultCollectionViewCell.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/7/16.
//
//

#import <UIKit/UIKit.h>
#import "MarqueeLabel.h"

@interface KBYTSearchResultCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *image;
@property (nonatomic, strong) IBOutlet MarqueeLabel *title;

@end
