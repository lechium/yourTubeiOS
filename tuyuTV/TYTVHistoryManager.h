//
//  TYTVHistoryManager.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/16/16.
//
//

#import <Foundation/Foundation.h>

@interface TYTVHistoryManager : NSObject

+ (id)sharedInstance;

- (void)addChannelToHistory:(NSDictionary *)channelDetails;
- (void)addVideoToHistory:(NSDictionary *)videoDetails;

- (NSArray *)channelHistoryObjects;

- (NSArray *)channelHistory;
- (NSArray *)videoHistory;

@end
