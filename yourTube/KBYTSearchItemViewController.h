

#import <UIKit/UIKit.h>
#import "KBYourTube.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>



@interface KBYTSearchItemViewController : UITableViewController {
	
    NSArray *airplayServers;
    NSArray *aircontrolServers;
}

@property (nonatomic, strong) KBYTMedia *ytMedia;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) NSString *airplayIP;

- (id)initWithMedia:(KBYTMedia *)media;

@end
