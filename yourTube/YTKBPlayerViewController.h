//
//  YTKBPlayerViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/2/16.
//
//

#import <AVKit/AVKit.h>
#import "KBYTQueuePlayer.h"
#import "KBYourTube.h"


@interface YTKBPlayerViewController : AVPlayerViewController <KBYTQueuePlayerDelegate>
{
    AVPlayerLayer *_layerToRestore;
}

@property (nonatomic, weak) NSArray *playlistItems;
@property (readwrite, assign) BOOL mediaIsLocal;
@property (nonatomic, strong) NSTimer *titleTimer;

- (id)initWithFrame:(CGRect)frame usingStreamingMediaArray:(NSArray *)streamingMedia;
- (id)initWithFrame:(CGRect)frame  usingLocalMediaArray:(NSArray *)localMediaArray;

- (void)addObjectsToPlayerQueue:(NSArray *)objects;

@end
