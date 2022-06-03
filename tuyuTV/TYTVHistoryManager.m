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

- (void)clearChannelHistory {
    [UD removeObjectForKey:@"ChannelHistory"];
}

- (void)clearVideoHistory {
    [UD removeObjectForKey:@"VideoHistory"];
}

- (NSArray *)videoHistoryObjects {
    NSArray *vidHistory = [self videoHistory];
    if (vidHistory != nil) {
        NSMutableArray *convertedArray = [NSMutableArray new];
        for (NSDictionary *videoDict in vidHistory) {
            NSString *duration = videoDict[@"duration"];
            if (![duration containsString:@":"]){
                duration = [NSString stringFromTimeInterval:[duration integerValue]];
            }
            KBYTSearchResult *result = [KBYTSearchResult new];
            result.videoId = videoDict[@"videoID"];
            result.title = videoDict[@"title"];
            result.author = videoDict[@"author"];
            result.duration = duration;
            result.resultType = kYTSearchResultTypeVideo;
            result.imagePath = videoDict[@"images"][@"high"];
            [convertedArray addObject:result];
        }
        return convertedArray;
    }
    
    return nil;
}

- (NSArray *)channelHistoryObjects {
    NSArray *prefHistory = [self channelHistory];
    if (prefHistory != nil) {
        NSMutableArray *convertedArray = [NSMutableArray new];
        for (NSDictionary *channelDict in prefHistory) {
            KBYTSearchResult *result = [KBYTSearchResult new];
            result.videoId = channelDict[@"channelID"];
            result.title = channelDict[@"title"];
            result.resultType = kYTSearchResultTypeChannel;
            result.imagePath = channelDict[@"image"];
            [convertedArray addObject:result];
        }
        return convertedArray;
    }
    
    return nil;
}

- (NSArray *)channelHistory {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:@"ChannelHistory"];
}
- (NSArray *)videoHistory {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:@"VideoHistory"];
}

- (void)addChannelToHistory:(NSDictionary *)channelDetails {
    NSMutableDictionary *channel = [channelDetails mutableCopy];

    [channel removeObjectForKey:@"sections"];
    NSArray *history = [self channelHistory];
    if (history == nil) {
        NSArray *newArray = @[channel];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"ChannelHistory"];
    } else {
        if ([history containsObject:channel]){
            return;
        }
        
        NSMutableArray *newArray = [history mutableCopy];
        [newArray addObject:channel];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"ChannelHistory"];
    }
}

- (void)addVideoToHistory:(NSDictionary *)videoDetails {
    NSLog(@"[tuyu] video history: %@", videoDetails);
    NSMutableDictionary *video = [videoDetails mutableCopy];
    [video removeObjectForKey:@"streams"];
    NSArray *history = [self videoHistory];
    if (history == nil) {
        NSArray *newArray = @[video];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"VideoHistory"];
    } else {
        if ([history containsObject:video]) {
            NSLog(@"[tuyu] item already exists");
            return;
        }
        NSMutableArray *newArray = [history mutableCopy];
        [newArray addObject:video];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"VideoHistory"];
    }
}

@end
