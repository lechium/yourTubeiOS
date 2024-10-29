//
//  ServiceProvider.m
//  tuyuShelf
//
//  Created by Kevin Bradley on 2/11/17.
//
//

#import "ServiceProvider.h"
#import "NSDictionary+serialize.h"
#import "TYTVHistoryManager.h"
@interface ServiceProvider ()


@property (nonatomic, strong) NSMutableArray *menuItems;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *playlists;
@end

@implementation ServiceProvider

+ (NSUserDefaults *)sharedUserDefaults {
    static dispatch_once_t pred;
    static NSUserDefaults* shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.tuyu"];
    });
    
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //[self testGetYTScience];
        self.menuItems = [NSMutableArray new];
        self.channels = [NSMutableArray new];
        self.playlists = [NSMutableArray new];
        //[self testGetYTScience];
    }
    return self;
}

#pragma mark - TVTopShelfProvider protocol

- (TVTopShelfContentStyle)topShelfStyle {
    // Return desired Top Shelf style.
    return TVTopShelfContentStyleSectioned;
}

- (NSString *)shelfFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"shelf.plist"];
}

- (void)loadDetailsFromDictionary:(NSDictionary *)dictionary {
    [self.channels removeAllObjects];
    [self.playlists removeAllObjects];
    NSString *channelID = dictionary[@"channelID"];
    NSArray <KBYTSearchResult *> *results = dictionary[@"results"];
    NSArray <KBYTSearchResult *> *rChannels = dictionary[@"channels"];
    [results enumerateObjectsUsingBlock:^(KBYTSearchResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.resultType ==kYTSearchResultTypeChannel)
        {
            [self.channels addObject:obj];
            
        } else if (obj.resultType ==kYTSearchResultTypePlaylist)
        {
            [self.playlists addObject:obj];
        }
        
    }];
    [self.channels addObjectsFromArray:rChannels];
    //[[NSNotificationCenter defaultCenter] postNotificationName:TVTopShelfItemsDidChangeNotification object:nil];
    [[KBYourTube sharedInstance] getChannelVideos:channelID completionBlock:^(KBYTChannel *channel) {
        [self.menuItems removeAllObjects];
        //self.menuItems = [channel.videos mutableCopy];
        TLog(@"channel videos: %@", channel.videos);
        [self.menuItems addObjectsFromArray:channel.videos];
        [[NSNotificationCenter defaultCenter] postNotificationName:TVTopShelfItemsDidChangeNotification object:nil];
    } failureBlock:^(NSString *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TVTopShelfItemsDidChangeNotification object:nil];
    }];
}

- (void)testGetYTScience {
    TLog(@"app support: %@", [self appSupportFolder]);
    NSString *fileTest = @"/var/mobile/Documents/test.txt";
    //[@"bro" writeToFile:fileTest atomically:true];
    NSString *string = [NSString stringWithContentsOfFile:fileTest];
    TLog(@"%@ contents: %@", fileTest, string);
    [[KBYourTube sharedUserDefaults] setObject:@"brosive" forKey:@"bruh"];
    NSArray *keys = [[[KBYourTube sharedUserDefaults] dictionaryRepresentation] allKeys];
    [keys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //TLog(@"key: %@", obj);
    }];
    //TLog(@"testKey: %@", [[[KBYourTube sharedUserDefaults] dictionaryRepresentation] allKeys]);
    //TLog(@"appCookies: %@", [[ServiceProvider sharedUserDefaults] valueForKey:@"ApplicationCookie"]);
    NSData *cookieData = [[ServiceProvider sharedUserDefaults] objectForKey:@"ApplicationCookie"];
    if ([cookieData length] > 0) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            //TLog(@"cookie: %@", cookie);
        }
    }
  
    
    if ([[KBYourTube sharedInstance] isSignedIn] == YES) {
        TLog(@"is signed in, get those sciences too!");
        if ([FM fileExistsAtPath:[self shelfFile]]) {
        NSDictionary *loadCache = [NSDictionary dictionaryWithContentsOfFile:[self shelfFile]];
            [self loadDetailsFromDictionary:[loadCache convertDictionaryToObjects]];
        }
        
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
            
            TLog(@"got outputResults: %@", outputResults);
            [[outputResults convertObjectsToDictionaryRepresentations] writeToFile:[self shelfFile] atomically:true];
            [self loadDetailsFromDictionary:outputResults];
            
        } failureBlock:^(NSString *error) {
            //
        }];
    } else {
        
        [[KBYourTube sharedInstance] getChannelVideosAlt:@"UCByOQJjav0CUDwxCk-jVNRQ" completionBlock:^(KBYTChannel *channel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.menuItems = [channel.allSectionItems mutableCopy];
                TLog(@"menuItems: %@", self.menuItems);
            });
        } failureBlock:^(NSString *error) {
            
        }];
    }
    
}

/*
 
 private func urlForIdentifier(identifier: String) -> NSURL {
 let components = NSURLComponents()
 components.scheme = "newsapp"
 components.queryItems = [NSURLQueryItem(name: "identifier",
 value: identifier)] return components.URL!
 }*/

- (NSURL *)urlForIdentifier:(NSString*)identifier type:(NSString *)type {
    return [NSURL URLWithString:[NSString stringWithFormat:@"tuyu://%@/%@", type, identifier]];
}


- (NSArray *)topShelfItems {
    LOG_SELF;
    // Create an array of TVContentItems.
    
    if (self.menuItems.count == 0 || self.menuItems == nil) {
        [self testGetYTScience];
    }
    // [self testGetYTScience];
    
    __block NSMutableArray *suggestedItems = [NSMutableArray new];
    __block NSMutableArray *channelItems = [NSMutableArray new];
    __block NSMutableArray *playlistItems = [NSMutableArray new];
    __block NSMutableArray *sectionItems = [NSMutableArray new];
    
    TVContentItem *historyItem = [self videoHistoryItem];
    if (historyItem.topShelfItems.count > 0) {
        [sectionItems addObject:historyItem];
    }
    
    if (self.channels.count > 0) {
        TLog(@"channels are greater than 0: %lu", self.channels.count);
        TVContentIdentifier *csection = [[TVContentIdentifier alloc] initWithIdentifier:@"channels" container:nil];
        TVContentItem * cItem = [[TVContentItem alloc] initWithContentIdentifier:csection];
        cItem.title = @"Channels";
        [self.channels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            KBYTSearchResult *result = (KBYTSearchResult *)obj;
            TVContentIdentifier *cid = [[TVContentIdentifier alloc] initWithIdentifier:result.videoId container:nil];
            TVContentItem * ci = [[TVContentItem alloc] initWithContentIdentifier:cid];
            ci.title = result.title;
            ci.imageURL = [NSURL URLWithString:result.imagePath];
            ci.displayURL = [self urlForIdentifier:result.videoId type:result.readableSearchType];
            [channelItems addObject:ci];
            
        }];
        cItem.topShelfItems = channelItems;
        [sectionItems addObject:cItem];
    }
    
    if (self.playlists.count > 0) {
        TLog(@"playlists are greater than 0: %lu", self.playlists.count);
        TVContentIdentifier *psection = [[TVContentIdentifier alloc] initWithIdentifier:@"playlists" container:nil];
        TVContentItem * pItem = [[TVContentItem alloc] initWithContentIdentifier:psection];
        pItem.title = @"Playlists";
        [self.playlists enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            KBYTSearchResult *result = (KBYTSearchResult *)obj;
            TVContentIdentifier *cid = [[TVContentIdentifier alloc] initWithIdentifier:result.videoId container:nil];
            TVContentItem * ci = [[TVContentItem alloc] initWithContentIdentifier:cid];
            ci.title = result.title;
            ci.imageURL = [NSURL URLWithString:result.imagePath];
            
            NSURLComponents *comp = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"tuyu://%@/%@", result.readableSearchType, result.videoId]];
            comp.query = [NSString stringWithFormat:@"title=%@", result.title];
            TLog(@"url: %@", comp.URL);
            ci.displayURL = comp.URL;
            [playlistItems addObject:ci];
            
        }];
        pItem.topShelfItems = playlistItems;
        [sectionItems addObject:pItem];
    }
    
    TVContentIdentifier *section = [[TVContentIdentifier alloc] initWithIdentifier:@"videos" container:nil];
    TVContentItem * sectionItem = [[TVContentItem alloc] initWithContentIdentifier:section];
    sectionItem.title = @"Videos";
    
    [self.menuItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        KBYTSearchResult *result = (KBYTSearchResult *)obj;
        TVContentIdentifier *cid = [[TVContentIdentifier alloc] initWithIdentifier:result.videoId container:nil];
        TVContentItem * ci = [[TVContentItem alloc] initWithContentIdentifier:cid];
        ci.title = result.title;
        ci.imageURL = [NSURL URLWithString:result.imagePath];
        ci.displayURL = [self urlForIdentifier:result.videoId type:result.readableSearchType];
        [suggestedItems addObject:ci];
        
    }];
    sectionItem.topShelfItems = suggestedItems;
    [sectionItems addObject:sectionItem];
    TLog(@"sectionItem: %@", sectionItem);
    return sectionItems;
}

- (TVContentItem *)videoHistoryItem {
    TVContentIdentifier *section = [[TVContentIdentifier alloc] initWithIdentifier:@"history" container:nil];
    TVContentItem * sectionItem = [[TVContentItem alloc] initWithContentIdentifier:section];
    sectionItem.title = @"Video History";
    NSMutableArray *historyItems = [NSMutableArray new];
    NSArray <KBYTSearchResult*> *videoHistoryItems = [[TYTVHistoryManager sharedInstance] videoHistoryObjects];
    for (KBYTSearchResult *result in videoHistoryItems) {
        TVContentIdentifier *cid = [[TVContentIdentifier alloc] initWithIdentifier:result.videoId container:nil];
        TVContentItem * ci = [[TVContentItem alloc] initWithContentIdentifier:cid];
        ci.title = result.title;
        ci.imageURL = [NSURL URLWithString:result.imagePath];
        ci.displayURL = [self urlForIdentifier:result.videoId type:result.readableSearchType];
        [historyItems addObject:ci];
    }
    sectionItem.topShelfItems = historyItems;
    return sectionItem;
    
}

@end
