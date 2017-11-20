

#import <UIKit/UIKit.h>
#import "KBYourTube.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "KBYTDownloadManager.h"

@protocol KBYTSearchItemViewControllerDelegate <NSObject>

- (void)playFromIndex:(NSInteger)index;

@end

@interface KBYTSearchItemViewController : UITableViewController {
	
    NSArray *airplayServers;
    NSArray *aircontrolServers;
}

@property (nonatomic, strong) KBYTMedia *ytMedia;
@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) NSString *airplayIP;
@property (nonatomic, weak) id <KBYTSearchItemViewControllerDelegate> delegate;
@property (readwrite, assign) NSInteger index;

- (id)initWithMedia:(KBYTMedia *)media;

@end
