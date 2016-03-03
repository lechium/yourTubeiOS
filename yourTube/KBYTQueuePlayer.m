//
//  KBYTQueuePlayer.m
//  IntervalPlayer
//
//  based on AVQueuePlayerPrevious by Daniel Giovannelli on 2/18/13.
//  updated to fork at https://github.com/brightskylabs/AVQueuePlayerPrevious/blob/master/AVQueuePlayerPrevious.m
//

#import "KBYTQueuePlayer.h"

@interface KBYTQueuePlayer ()

// This is a flag used to mark whether an item being added to the queue is being added by playPreviousItem (which requires slightly different functionality then in the general case) or if it is being added by an external call
@property (nonatomic) BOOL isCalledFromPlayPreviousItem;

@property (nonatomic) NSInteger nowPlayingIndex;
@property (readwrite) NSMutableArray *innerItems;

@end

@implementation KBYTQueuePlayer

- (instancetype)initWithItems:(NSArray *)items {
    // This function calls the constructor for AVQueuePlayer, then sets up the nowPlayingIndex to 0 and saves the array that the player was generated from as itemsForPlayer
    self = [super initWithItems:items];
    if (self){
        _innerItems = [NSMutableArray arrayWithArray:items];
        _nowPlayingIndex = 0;
        _isCalledFromPlayPreviousItem = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songEnded:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

+ (KBYTQueuePlayer *)queuePlayerWithItems:(NSArray *)items
{
    // This function just allocates space for, creates, and returns an AVQueuePlayerPrevious from an array.
    // Honestly I think having it is a bit silly, but since its present in AVQueuePlayer it needs to be
    // overridden here to ensure compatability.
    KBYTQueuePlayer *playerToReturn = [[KBYTQueuePlayer alloc] initWithItems:items];
    return playerToReturn;
}

- (NSArray *)itemsForPlayer {
    return [self.innerItems copy];
}

- (void)setNowPlayingIndex:(NSInteger)nowPlayingIndex {
    NSInteger previousIndex = _nowPlayingIndex;
    _nowPlayingIndex = nowPlayingIndex;
    if ([self.delegate respondsToSelector:@selector(queuePlayer:didStartPlayingItem:)] && nowPlayingIndex < self.innerItems.count && previousIndex != nowPlayingIndex) {
        [self.delegate queuePlayer:self didStartPlayingItem:self.innerItems[nowPlayingIndex]];
    }
}

- (void)songEnded:(NSNotification *)notification {
    if (self.nowPlayingIndex < [self.innerItems count] - 1) {
        self.nowPlayingIndex++;
    } else {
        [self playBeginningItem];
    }
}

- (void)playPreviousItem {
    if (self.nowPlayingIndex <= 0){
        return;
    }
    
    self.isCalledFromPlayPreviousItem = YES;
    
    [self pause];
    // Note: it is necessary to have seekToTime called twice in this method, once before and once after re-making the area. If it is not present before, the player will resume from the same spot in the next song when the previous song finishes playing; if it is not present after, the previous song will be played from the same spot that the current song was on.
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    // The next two lines are necessary since RemoveAllItems resets both the nowPlayingIndex and _itemsForPlayer
    int tempNowPlayingIndex = self.nowPlayingIndex;
    NSMutableArray *tempPlaylist = [[NSMutableArray alloc]initWithArray:self.innerItems];
    [self removeAllItems];
    for (int i = tempNowPlayingIndex - 1; i < [tempPlaylist count]; i++) {
        [self insertItem:[tempPlaylist objectAtIndex:i] afterItem:nil];
    }
    // The temp index is necessary since removeAllItems resets the nowPlayingIndex
    self.nowPlayingIndex = tempNowPlayingIndex - 1;
    // Not a typo; see above comment
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self play];
    
    self.isCalledFromPlayPreviousItem = NO;
}

- (NSInteger)index {
    return self.nowPlayingIndex;
}

- (void)playBeginningItem {
    self.isCalledFromPlayPreviousItem = YES;
    
    [self pause];
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    NSMutableArray *tempPlaylist = [[NSMutableArray alloc]initWithArray:self.innerItems];
    [self removeAllItems];
    for (AVPlayerItem *item in tempPlaylist) {
        [self insertItem:item afterItem:nil];
    }
    // The temp index is necessary since removeAllItems resets the nowPlayingIndex
    self.nowPlayingIndex = 0;
    // Not a typo; see above comment
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self play];
    
    self.isCalledFromPlayPreviousItem = NO;
}

#pragma mark - AVQueuePlayer Methods

- (void)removeAllItems {
    // This does the same thing as the normal AVQueuePlayer removeAllItems, but also sets the
    // nowPlayingIndex to 0.
    [super removeAllItems];
    self.nowPlayingIndex = 0;
    
    if (!self.isCalledFromPlayPreviousItem) {
        [self.innerItems removeAllObjects];
    }
}

- (void)removeItem:(AVPlayerItem *)item {
    // This method calls the superclass to remove the items from the AVQueuePlayer itself, then removes
    // any instance of the item from the itemsForPlayer array. This mimics the behavior of removeItem on
    // AVQueuePlayer, which removes all instances of the item in question from the queue.
    // It also subtracts 1 from the nowPlayingIndex for every time the item shows up in the itemsForPlayer
    // array before the current value.
    [super removeItem:item];
    int appearancesBeforeCurrent = 0;
    for (int tracer = 0; tracer < self.nowPlayingIndex; tracer++){
        if ([self.innerItems objectAtIndex:tracer] == item) {
            appearancesBeforeCurrent++;
        }
    }
    self.nowPlayingIndex -= appearancesBeforeCurrent;
    [self.innerItems removeObject:item];
}

- (void)advanceToNextItem {
    // The only addition this method makes to AVQueuePlayer is advancing the nowPlayingIndex by 1.
    [super advanceToNextItem];
    if (self.nowPlayingIndex < [self.innerItems count] - 1){
        self.nowPlayingIndex++;
    } else {
        [self playBeginningItem];
    }
    [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)insertItem:(AVPlayerItem *)item afterItem:(AVPlayerItem *)afterItem {
    // This method calls the superclass to add the new item to the AVQueuePlayer, then adds that item to the
    // proper location in the itemsForPlayer array and increments the nowPlayingIndex if necessary.
    [super insertItem:item afterItem:afterItem];
    if (!self.isCalledFromPlayPreviousItem){
        if ([self.innerItems indexOfObject:item] < self.nowPlayingIndex) {
            self.nowPlayingIndex++;
        }
    }
    
    if (self.isCalledFromPlayPreviousItem) {
        return;
    }
    
    if ([self.innerItems containsObject:afterItem]){ // AfterItem is non-nil
        if ([self.innerItems indexOfObject:afterItem] < [self.innerItems count] - 1){
            [self.innerItems insertObject:item atIndex:[self.innerItems indexOfObject:afterItem] + 1];
        } else {
            [self.innerItems addObject:item];
        }
    } else { // afterItem is nil
        [self.innerItems addObject:item];
    }
}

- (void)play {
    [super play];
    if ([self.delegate respondsToSelector:@selector(queuePlayer:didStartPlayingItem:)] && !self.isCalledFromPlayPreviousItem && self.nowPlayingIndex < self.innerItems.count) {
        [self.delegate queuePlayer:self didStartPlayingItem:self.innerItems[self.nowPlayingIndex]];
    }
}

- (void)addItemToQueue:(id)itemToAdd
{
    id lastObject = [[self items] lastObject];
    [self insertItem:itemToAdd afterItem:lastObject];
}


@end
