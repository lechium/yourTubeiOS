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
            if (result.title != nil) {
                [convertedArray addObject:result];
            }
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
    //TLog(@"add to channel to history: %@", channelDetails);
    NSMutableDictionary *channel = [channelDetails mutableCopy];

    [channel removeObjectForKey:@"sections"];
    NSArray *history = [self channelHistory];
    if (history == nil) {
        NSArray *newArray = @[channel];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"ChannelHistory"];
    } else {
        NSMutableArray *newArray = [history mutableCopy];
        NSArray *foundItems = [history filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"channelID == %@", channelDetails[@"channelID"]]];
        if (foundItems.count > 0) {
            //TLog(@"items already exists: %@", foundItems);
            [newArray removeObjectsInArray:foundItems];
        }
        //[newArray addObject:channel];
        [newArray insertObject:channel atIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"ChannelHistory"];
    }
    [[KBYourTube sharedInstance] postUserDataChangedNotification];
}

- (void)addVideoToHistory:(NSDictionary *)videoDetails {
    if (!videoDetails) return;
    //TLog(@"add to video history: %@", videoDetails);
    NSMutableDictionary *video = [videoDetails mutableCopy];
    [video removeObjectForKey:@"streams"];
    NSArray *history = [self videoHistory];
    if (history == nil) {
        NSArray *newArray = @[video];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"VideoHistory"];
    } else { //channelID
        NSMutableArray *newArray = [history mutableCopy];
        NSArray *foundItems = [history filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"videoID == %@", videoDetails[@"videoID"]]];
        
        if (foundItems.count > 0) {
            //TLog(@"items already exists: %@", foundItems);
            [newArray removeObjectsInArray:foundItems];
        }
        //[newArray addObject:video];
        [newArray insertObject:video atIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"VideoHistory"];
    }
    [[KBYourTube sharedInstance] postUserDataChangedNotification];
}

@end
