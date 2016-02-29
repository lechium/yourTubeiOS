//
//  KBYTDownloadsTableViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 1/27/16.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "KBYTDownloadCell.h"
#import "RNFrostedSidebar/RNFrostedSidebar.h"
#import "KBYTGenericVideoTableViewController.h"

@interface KBYTDownloadsTableViewController : UITableViewController <RNFrostedSidebarDelegate>
@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, strong) AVPlayerViewController *playerView;
@property (nonatomic, strong) NSArray *downloadArray;
@property (nonatomic, strong) NSArray *activeDownloads;
@property (nonatomic, strong) NSMutableIndexSet *optionIndices;
@property (nonatomic, strong) NSMutableArray *currentPlaybackArray;
- (void)reloadData;
- (void)delayedReloadData;
- (void)updateDownloadProgress:(NSDictionary *)theDict;
@end
