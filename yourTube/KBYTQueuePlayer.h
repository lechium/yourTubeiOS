//
//  KBYTQueuePlayer.h
//  IntervalPlayer
//
//  Created by Daniel Giovannelli on 2/18/13.
//  This class subclasses AVQueuePlayer to create a class with the same functionality as AVQueuePlayer
//  but with the added ability to go backwards in the queue - a function that is impossible in a normal 
//  AVQueuePlayer since items on the queue are destroyed when they are finished playing.
//
//  IMPORTANT NOTE: This version of AVQueuePlayer assumes that ARC IS ENABLED. If ARC is NOT enabled and you
//  use this library, you'll get memory leaks on the two fields that have been added to the class, int
//  nowPlayingIndex and NSArray itemsForPlayer. 
//
//  Note also that this classrequires that the AVFoundation framework be included in your project.

#import <AVFoundation/AVFoundation.h>

@class KBYTQueuePlayer;

@protocol KBYTQueuePlayerDelegate <NSObject>
@optional

- (void)queuePlayer:(KBYTQueuePlayer *)player didStartPlayingItem:(AVPlayerItem *)item;

@end

@interface KBYTQueuePlayer : AVQueuePlayer

@property (nonatomic, weak) id <KBYTQueuePlayerDelegate> delegate;
@property (nonatomic, readonly) NSArray *itemsForPlayer;
@property (nonatomic, readonly) NSInteger index;

- (void)playPreviousItem;
- (void)playBeginningItem;
- (void)addItemToQueue:(id)itemToAdd;

@end
