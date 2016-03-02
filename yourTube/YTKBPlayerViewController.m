//
//  YTKBPlayerViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/2/16.
//
//

#import "YTKBPlayerViewController.h"


@implementation YTKBPlayerViewController

@synthesize mediaIsLocal, titleTimer;

/*
 
 most of the code in this class are the stupid hurdles to jump through to not roll your own AVPlayerView &
 & controller but to maintain playback in the background & then regain video in the foreground.
 
 adapted and fixed from http://stackoverflow.com/questions/31621618/remove-and-restore-avplayer-to-enable-background-video-playback/33240738#33240738
 
 
 */

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    MPRemoteCommandCenter *shared = [MPRemoteCommandCenter sharedCommandCenter];
    [shared.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        [[self player] pause];
        return MPRemoteCommandHandlerStatusSuccess;
        
    }];
    
    [shared.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        [[self player] play];
        return MPRemoteCommandHandlerStatusSuccess;
        
    }];
    
    [shared.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        
        NSArray *playerItems = [(AVQueuePlayer *)[self player] items];
        NSObject <YTPlayerItemProtocol> *currentItem = [[playerItems firstObject] associatedMedia];
        [(AVQueuePlayer *)[self player] advanceToNextItem];
        playerItems = [(AVQueuePlayer *)[self player] items];
        currentItem = [[playerItems firstObject] associatedMedia];
        NSString *duration = [currentItem duration];
        NSNumber *usableDuration = nil;
        if ([duration containsString:@":"])
        {
            usableDuration = [NSNumber numberWithInteger:[[currentItem duration]timeFromDuration]];
        } else {
            NSNumberFormatter *numFormatter = [NSNumberFormatter new];
            usableDuration = [numFormatter numberFromString:duration];
        }
        NSLog(@"nextTrackCommandCI: %@", currentItem.title);
        if (currentItem == nil) { return MPRemoteCommandHandlerStatusCommandFailed; }
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : currentItem.title, MPMediaItemPropertyPlaybackDuration: usableDuration };
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [shared.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
       
        [(KBYTQueuePlayer *)[self player] playPreviousItem];
        return MPRemoteCommandHandlerStatusSuccess;
        
    }];
    
    self.titleTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setNowPlayingInfo) userInfo:nil repeats:true];
    
    
}

- (id)initWithFrame:(CGRect)frame usingStreamingMediaArray:(NSArray *)streamingMedia
{
    self = [super init];
    mediaIsLocal = false;
    
    NSMutableArray *avPlayerItemArray = [NSMutableArray new];
    for (KBYTSearchResult *result in streamingMedia)
    {
        if ([result media] != nil)
        {
            YTPlayerItem *playerItem = [[YTPlayerItem alloc] initWithURL:[[[[result media]streams] firstObject]url]];
            playerItem.associatedMedia = [result media];
            if (playerItem != nil)
            {
                [avPlayerItemArray addObject:playerItem];
            }
        }
    }
    
    self.showsPlaybackControls = true;
    self.player = [KBYTQueuePlayer queuePlayerWithItems:avPlayerItemArray];
    [(KBYTQueuePlayer *)self.player setDelegate:self];
    self.view.frame = frame;
    return self;
}

- (id)initWithFrame:(CGRect)frame usingLocalMediaArray:(NSArray *)localMediaArray
{
    self = [super init];
    mediaIsLocal = true;
    NSMutableArray *avPlayerItemArray = [NSMutableArray new];
    
    for (KBYTLocalMedia *file in localMediaArray)
    {
        NSString *filePath = file.filePath;
        NSURL *playURL = [NSURL fileURLWithPath:filePath];
        YTPlayerItem *playerItem = [[YTPlayerItem alloc] initWithURL:playURL];
        playerItem.associatedMedia = file;
        NSLog(@"associatedMedia: %@", file.title);
        [avPlayerItemArray addObject:playerItem];
    }
    
    KBYTLocalMedia *file = [localMediaArray objectAtIndex:0];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : file.title, MPMediaItemPropertyPlaybackDuration: file.duration };
    self.showsPlaybackControls = true;
    self.player = [KBYTQueuePlayer queuePlayerWithItems:avPlayerItemArray];
    [(KBYTQueuePlayer *)self.player setDelegate:self];
    self.view.frame = frame;
    return self;
}


- (void)setNowPlayingInfo
{
    NSArray *playerItems = [(AVQueuePlayer *)[self player] items];
    YTPlayerItem *currentPlayerItem = [playerItems firstObject];
    double currentTime = currentPlayerItem.currentTime.value/currentPlayerItem.currentTime.timescale;
    NSObject <YTPlayerItemProtocol> *currentItem = [[playerItems firstObject] associatedMedia];
    //NSLog(@"currentItem: %@", currentItem);
    NSString *duration = [currentItem duration];
    NSNumber *usableDuration = nil;
    if ([duration containsString:@":"])
    {
        usableDuration = [NSNumber numberWithInteger:[[currentItem duration]timeFromDuration]];
    } else {
        NSNumberFormatter *numFormatter = [NSNumberFormatter new];
        usableDuration = [numFormatter numberFromString:duration];
    }
    if (currentItem == nil) { return; }
    
    if ([MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo  != nil){
        
        NSMutableDictionary *nowPlayingInfo = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:currentTime];
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentItem.title;
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = usableDuration;
        
    } else {

        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : currentItem.title, MPMediaItemPropertyPlaybackDuration: usableDuration }; //, MPMediaItemPropertyArtwork: artwork };
    
    }
}

-(void)queuePlayerDidReceiveNotificationForSongIncrement:(KBYTQueuePlayer*)previousPlayer
{
    LOG_SELF;
    if ([[(KBYTQueuePlayer *)self.player items] count] == 0)
    {

        [self dismissViewControllerAnimated:true completion:nil];
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    } else {
        [self setNowPlayingInfo];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand removeTarget:self];
    [[MPRemoteCommandCenter sharedCommandCenter].playCommand removeTarget:self];
    [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand removeTarget:self];
     [[MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand removeTarget:self];
    [(AVQueuePlayer *)[self player] removeAllItems];
    self.player = nil;
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    if ([self titleTimer] != nil)
    {
        if ([self.titleTimer isValid])
        {
            [self.titleTimer invalidate];
            self.titleTimer = nil;
        }
    }
    // [[self player] stop];
}

- (void)didForeground:(NSNotification *)n
{
    if (_layerToRestore != nil)
    {
        [_layerToRestore setPlayer:[self player]];
        _layerToRestore = nil;
    }
}

- (AVPlayerLayer *)findPlayerView {
    return [self findLayerWithAVPlayerLayer:self.view];
}

- (AVPlayerLayer *)findLayerWithAVPlayerLayer:(UIView *)view {
    AVPlayerLayer *foundView = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0"))
    {
        if ([view.layer isKindOfClass:[AVPlayerLayer class]]) {
            return (AVPlayerLayer *)view.layer;
        }
    } else {
        @try {
            foundView = [view valueForKey:@"_videoLayer"];
        }
        @catch ( NSException *e ) {
            //  NSLog(@"exception: %@", e);
        }
        @finally
        {
            if (foundView != nil)
            {
                return foundView;
            }
        }
    }
    
    for (UIView *v in view.subviews) {
        AVPlayerLayer *theLayer = [self findLayerWithAVPlayerLayer:v];
        if (theLayer != nil)
        {
            return theLayer;
        }
    }
    return nil;
}

- (BOOL)isPlaying
{
    if ([self player] != nil)
    {
        if (self.player.rate != 0)
        {
            return true;
        }
    }
    return false;
    
}

- (BOOL)hasVideo
{
    AVPlayerItem *playerItem = [[self player] currentItem];
    NSArray *tracks = [playerItem tracks];
    for (AVPlayerItemTrack *playerItemTrack in tracks)
    {
        // find video tracks
        if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicVisual])
        {
            //playerItemTrack.enabled = NO; // disable the track
            return true;
        }
    }
    return false;
}

- (void)didBackground:(NSNotification *)n
{
    [self setNowPlayingInfo];
    // NSString *recursiveDesc = [self.view performSelector:@selector(recursiveDescription)];
    //NSLog(@"### view recursiveDescription: %@", recursiveDesc);
    if ([self isPlaying] == true && [self hasVideo] == true)
    {
        
        _layerToRestore = [self findPlayerView];
        [_layerToRestore setPlayer:nil];
        
    }
}

- (BOOL)shouldAutorotate
{
    return TRUE;
}

@end
