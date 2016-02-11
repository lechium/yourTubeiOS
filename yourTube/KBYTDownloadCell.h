//
//  KBYTDownloadCell.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/10/16.
//
//

#import <UIKit/UIKit.h>
#import "MarqueeLabel/MarqueeLabel.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "JGProgressView/JGProgressView.h"

@interface KBYTDownloadCell: UITableViewCell

@property (nonatomic, strong) MarqueeLabel *marqueeTextLabel;
@property (nonatomic, strong) MarqueeLabel *marqueeDetailTextLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *viewsLabel;
@property (nonatomic, strong) JGProgressView *progressView;
@property (readwrite, assign) BOOL downloading;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSString *views;

@end
