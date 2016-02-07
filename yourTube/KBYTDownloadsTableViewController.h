//
//  KBYTDownloadsTableViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 1/27/16.
//
//

#import <UIKit/UIKit.h>
#import "MarqueeLabel/MarqueeLabel.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface KBYTDownloadCell: UITableViewCell

@property (nonatomic, strong) MarqueeLabel *marqueeTextLabel;
@property (nonatomic, strong) MarqueeLabel *marqueeDetailTextLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (readwrite, assign) BOOL downloading;

@end

@interface KBYTDownloadsTableViewController : UITableViewController
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerViewController *playerView;
@property (nonatomic, strong) NSArray *downloadArray;
@property (nonatomic, strong) NSArray *activeDownloads;

- (void)reloadData;
- (void)delayedReloadData;
- (void)updateDownloadProgress:(NSDictionary *)theDict;
@end
