//
//  TYTVHistoryManager.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/16/16.
//
//

#import "TYTVHistoryManager.h"
#import "KBYourTube.h"

@implementation TYTVHistoryManager

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static TYTVHistoryManager *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            shared = [TYTVHistoryManager new];
        });
    }
    
    return shared;
    
}

- (NSArray *)channelHistoryObjects
{
    NSArray *prefHistory = [self channelHistory];
    if (prefHistory != nil)
    {
        NSMutableArray *convertedArray = [NSMutableArray new];
        for (NSDictionary *channelDict in prefHistory)
        {
            KBYTSearchResult *result = [KBYTSearchResult new];
            result.videoId = channelDict[@"channelID"];
            result.title = channelDict[@"name"];
            result.author = channelDict[@"author"];
            result.resultType = kYTSearchResultTypeChannel;
            result.imagePath = channelDict[@"thumbnail"];
            [convertedArray addObject:result];
        }
        return convertedArray;
    }
    
    return nil;
}

- (NSArray *)channelHistory
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:@"ChannelHistory"];
}
- (NSArray *)videoHistory
{
    return [[NSUserDefaults standardUserDefaults] arrayForKey:@"VideoHistory"];
}

- (void)addChannelToHistory:(NSDictionary *)channelDetails
{
    NSMutableDictionary *channel = [channelDetails mutableCopy];

    [channel removeObjectForKey:@"results"];
    [channel removeObjectForKey:@"playlists"];
    DLog(@"channel: %@", channel);
    NSArray *history = [self channelHistory];
    if (history == nil)
    {
        NSArray *newArray = @[channel];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"ChannelHistory"];
    } else {
        
        if ([history containsObject:channel])
        {
            return;
        }
        
        NSMutableArray *newArray = [history mutableCopy];
        [newArray addObject:channel];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"ChannelHistory"];
    }
}

- (void)addVideoToHistory:(NSDictionary *)videoDetails
{
    NSMutableDictionary *video = [videoDetails mutableCopy];
    [video removeObjectForKey:@"streams"];
    NSArray *history = [self videoHistory];
    if (history == nil)
    {
        NSArray *newArray = @[video];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"VideoHistory"];
    } else {
        NSMutableArray *newArray = [history mutableCopy];
        [newArray addObject:video];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"VideoHistory"];
    }
}


@end
