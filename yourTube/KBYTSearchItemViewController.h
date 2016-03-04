

#import <UIKit/UIKit.h>
#import "KBYourTube.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "KBYTDownloadManager.h"


@interface KBYTSearchItemViewController : UITableViewController {
	
    NSArray *airplayServers;
    NSArray *aircontrolServers;
}

@property (nonatomic, strong) KBYTMedia *ytMedia;
@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) NSString *airplayIP;

- (id)initWithMedia:(KBYTMedia *)media;

@end
