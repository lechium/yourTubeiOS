//
//  KBVideoPlaybackProtocol.h
//  Ethereal
//
//  Created by kevinbradley on 9/18/21.
//  Copyright © 2021 nito. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KBVideoPlayerProtocol <NSObject>

- (void)play;
- (void)pause;
- (id)currentItem;
- (CGFloat)rate;
- (AVPlayerTimeControlStatus) timeControlStatus;
- (void)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter;
@optional
- (void)observeStatus;
- (void)switchSubtitleStream:(int)index;
@end

@protocol KBVideoPlaybackProtocol <NSObject>
//@property (nonatomic, strong) NSURL *mediaURL;
@property (nonatomic, strong) id <KBVideoPlayerProtocol> player;
@property (nonatomic, weak) id currentAsset;

- (BOOL)setMediaURL:(NSURL *)mediaURL;
- (NSURL *)mediaURL;

@end

NS_ASSUME_NONNULL_END
