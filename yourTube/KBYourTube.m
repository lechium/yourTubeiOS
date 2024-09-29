//
//  KBYourTube.m
//  yourTube
//
//  Created by Kevin Bradley on 12/21/15.
//  Copyright © 2015 nito. All rights reserved.
//

#import "KBYourTube.h"
#import "APDocument/APXML.h"
#import "Ono/ONOXMLDocument.h"
#import "KBYourTube+Categories.h"
#import <CoreMedia/CoreMedia.h>
#import "MetadataPreviewView.h"
#import "NSDictionary+serialize.h"
#ifndef SHELF_EXT
#import "KBAVMetaData.h"
#endif
//#ifndef SHELF_EXT
#import "TYAuthUserManager.h"
#import "EXTScope.h"
//#endif

#if TARGET_OS_TV
#import "TYTVHistoryManager.h"
#endif

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

static NSString * const hardcodedTimestamp = @"16864";
static NSString * const hardcodedCipher = @"42,0,14,-3,0,-1,0,-2";

/**
 
 out of pure laziness I put the implementation KBYTStream and KBYTMedia classes in this file and their interfaces
 in the header file. However, it does provide easier portability since I have yet to make this into a library/framework/pod
 
 
 */

@implementation KBYTSection
- (NSString *)description {
    NSString *desc = [super description];
    return [NSString stringWithFormat:@"%@ title: %@ content count: %lu", desc,self.title, self.content.count];
}

- (void)addResult:(KBYTSearchResult *)result {
    if (!result) return;
    NSLog(@"adding result: %@", result);
    NSMutableArray *_mutContent = [[self content] mutableCopy];
    if (!_mutContent) _mutContent = [NSMutableArray new];
    [_mutContent addObject:result];
    self.content = _mutContent;
}

@end

@implementation KBYTChannel

- (NSString *)description {
    NSString *desc = [super description];
    return [NSString stringWithFormat:@"%@ videos: %@ title: %@ ID: %@", desc, _videos, _title, _channelID];
}

- (void)mergeChannelVideos:(KBYTChannel *)channel {
    NSMutableArray *newVideos = [self.videos mutableCopy];
    //TLog(@"new channel: %@", channel.videos);
    //TLog(@"current videos: %@", self.videos);
    [newVideos addObjectsFromArray:channel.videos];
    self.continuationToken = channel.continuationToken;
    self.videos = newVideos;
}

- (NSArray <KBYTSearchResult *>*)allSortedItems {
    if (self.videos.count > 0 && self.playlists.count > 0){
        NSMutableArray *_newArray = [[self videos] mutableCopy];
        //TLog(@"playlists: %@", self.playlists);
        [_newArray addObjectsFromArray:self.playlists];
        NSSortDescriptor *title = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:true];
        [_newArray sortUsingDescriptors:@[title]];
        return _newArray;
    } else {
        return self.videos;
    }
    return self.videos;
}

- (NSArray <KBYTSearchResult *>*)allSectionItems {
    if (self.sections.count == 0) {
        return [self allSortedItems];
    }
    __block NSMutableArray *_newArray = [NSMutableArray new];
    [self.sections enumerateObjectsUsingBlock:^(KBYTSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [_newArray addObjectsFromArray:obj.content];
    }];
    return _newArray;
}

@end

@implementation KBYTPlaylist

- (NSString *)description {
    NSString *desc = [super description];
    return [NSString stringWithFormat:@"%@ videos: %@ title: %@ ID: %@", desc, _videos, _title, _playlistID];
}


@end

@implementation KBYTSearchResults

- (NSString *)description {
    NSString *desc = [super description];
    return [NSString stringWithFormat:@"%@ videos: %@ playlists: %@ channels: %@ cc: %@ results count: %lu", desc, _videos, _playlists, _channels, _continuationToken, _estimatedResults];
}

- (void)processJSON:(NSDictionary *)jsonData {
    [self processJSON:jsonData filter:KBYTSearchTypeAll];
}




- (void)processJSON:(NSDictionary *)jsonDict filter:(KBYTSearchType)filter {
    
    NSInteger estimatedResults = [[jsonDict recursiveObjectForKey:@"estimatedResults"] integerValue];
    self.estimatedResults = estimatedResults;
    id cc = [jsonDict recursiveObjectForKey:@"continuationCommand"];
    recursiveObjectsFor(@"continuationCommand", jsonDict, ccs);
    //DLog(@"ccs: %@", ccs);
    self.continuationToken = cc[@"token"];
    //NSLog(@"cc: %@", cc);
    if (filter == KBYTSearchTypeAll) {
        __block NSMutableArray *videoResults = [NSMutableArray new];
        recursiveObjectsLike(@"videoRenderer", jsonDict, videos);
        [videos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            KBYTSearchResult *searchItem = [[KBYourTube sharedInstance] searchResultFromVideoRenderer:obj];
            if (searchItem.title.length > 0 && searchItem.videoId.length > 0){
                [videoResults addObject:searchItem];
            }
        }];
        self.videos = videoResults;
    }
    
    //TLog(@"playlist count: %lu", playlists.count);
    if (filter == KBYTSearchTypeAll || filter == KBYTSearchTypePlaylists) {
        __block NSMutableArray *playlistResults = [NSMutableArray new];
        recursiveObjectsFor(@"playlistRenderer", jsonDict, playlists);
        [playlists enumerateObjectsUsingBlock:^(id  _Nonnull current, NSUInteger idx, BOOL * _Nonnull stop) {
            //NSDictionary *current = obj[@"playlistRenderer"];
            NSDictionary *title = [current recursiveObjectForKey:@"title"];
            NSString *pis = current[@"playlistId"];
            NSArray *thumbnails = [current recursiveObjectForKey:@"thumbnail"][@"thumbnails"];
            NSString *imagePath = thumbnails.lastObject[@"url"];
            if (![imagePath containsString:@"https:"]){
                imagePath = [NSString stringWithFormat:@"https:%@", imagePath];
            }
            NSDictionary *longBylineText = current[@"longBylineText"];
            KBYTSearchResult *searchItem = [KBYTSearchResult new];
            searchItem.author = [longBylineText recursiveObjectForKey:@"text"];
            searchItem.title = title[@"simpleText"];
            searchItem.videoId = pis;
            searchItem.imagePath = imagePath;
            searchItem.resultType = kYTSearchResultTypePlaylist;
            searchItem.details = [current recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"browseId"];
            NSArray *itemDesc = [current recursiveObjectForKey:@"descriptionSnippet"][@"runs"];
            searchItem.itemDescription = [itemDesc runsToString];
            if (!title){
                //TLog(@"weird pl item: %@", current);
                //TLog(@"pl item: %@", searchItem);
            }
            /*
             NSString *outputFile = [[NSHomeDirectory() stringByAppendingPathComponent:searchItem.title] stringByAppendingPathExtension:@"plist"];
             [current writeToFile:outputFile atomically:true];
             TLog(@"writing playlist: %@", outputFile);
             */
            [playlistResults addObject:searchItem];
        }];
        self.playlists = playlistResults;
    }
    if (filter == KBYTSearchTypeAll || filter == KBYTSearchTypeChannels) {
        __block NSMutableArray *channelResults = [NSMutableArray new];
        recursiveObjectsFor(@"channelRenderer", jsonDict, channels);
        [channels enumerateObjectsUsingBlock:^(id  _Nonnull current, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *title = [current recursiveObjectForKey:@"title"];
            NSString *cis = current[@"channelId"];
            NSArray *thumbnails = [current recursiveObjectForKey:@"thumbnail"][@"thumbnails"];//current[@"thumbnail"][@"thumbnails"];
            NSString *imagePath = thumbnails.lastObject[@"url"];
            if (![imagePath containsString:@"https:"]){
                imagePath = [NSString stringWithFormat:@"https:%@", imagePath];
            }
            NSDictionary *longBylineText = current[@"longBylineText"];
            KBYTSearchResult *searchItem = [KBYTSearchResult new];
            searchItem.author = [longBylineText recursiveObjectForKey:@"text"];
            searchItem.title = title[@"simpleText"];
            searchItem.videoId = cis;
            searchItem.imagePath = imagePath;
            searchItem.resultType = kYTSearchResultTypeChannel;
            searchItem.details = [current recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"canonicalBaseUrl"];
            NSArray *itemDesc = [current recursiveObjectForKey:@"descriptionSnippet"][@"runs"];
            searchItem.itemDescription = [itemDesc runsToString];
            if (!title){
                //TLog(@"weird channel item: %@", current);
            }
            /*
             NSString *outputFile = [[NSHomeDirectory() stringByAppendingPathComponent:searchItem.title] stringByAppendingPathExtension:@"plist"];
             [current writeToFile:outputFile atomically:true];
             TLog(@"writing channel: %@", outputFile);*/
            [channelResults addObject:searchItem];
        }];
        self.channels = channelResults;
    }

}

- (NSArray <KBYTSearchResult *> *)allItems {
    NSMutableArray *_allItems = [self.videos mutableCopy];
    if (!_allItems) _allItems = [NSMutableArray new];
    [_allItems addObjectsFromArray:self.channels];
    [_allItems addObjectsFromArray:self.playlists];
    return _allItems;
}

@end

@implementation KBYTLocalMedia

@synthesize author, title, images, inProgress, videoId, views, duration, extension, filePath, format, outputFilename;

- (id)initWithDictionary:(NSDictionary *)inputDict {
    self = [super init];
    author = inputDict[@"author"];
    title = inputDict[@"title"];
    inProgress = [inputDict[@"inProgress"] boolValue];
    videoId = inputDict[@"videoId"];
    duration = inputDict[@"duration"];
    images = inputDict[@"images"];
    views = inputDict[@"views"];
    extension = inputDict[@"extension"];
    format = inputDict[@"format"];
    outputFilename = inputDict[@"outputFilename"];
    filePath = [[self downloadFolder] stringByAppendingPathComponent:outputFilename];
    return self;
}

- (NSDictionary *)dictionaryValue {
    if (self.title == nil)self.title = @"Unavailable";
    if (self.views == nil)self.views = @"Unavailable";
    if (self.author == nil)self.author = @"Unavailable";
    if (self.duration == nil)self.duration = @"Unavailable";
    if (self.videoId == nil)self.videoId = @"Unavailable";
    if (self.outputFilename == nil)self.outputFilename = @"Unavailable";
    if (self.format == nil)self.format = @"Unavailable";
    if (self.images == nil)self.images = @{};
    return @{@"title": self.title, @"author": self.author, @"outputFilename": self.outputFilename, @"images": self.images, @"videoId": self.videoId, @"duration": self.duration, @"inProgress": [NSNumber numberWithBool:self.inProgress], @"views": self.views, @"extension": self.extension, @"format": self.format};
}

- (NSString *)description {
    return [[self dictionaryValue] description];
}

@end


/*
 
 KBYTSearchResult keep track of search results through the new HTML scraping search methods that supplanted
 the old web view that was used in earlier versions.
 
 */

@implementation KBYTSearchResult

@synthesize title, author, details, imagePath, videoId, duration, age, views, resultType;

-(instancetype)initWithTitle:(NSString *)title imagePath:(NSString *)path uniqueID:(NSString *)unique type:(YTSearchResultType)type {
    KBYTSearchResult *result = [KBYTSearchResult new];
    result.videoId = unique; //for now
    result.channelId = unique; //ditto
    result.playlistId = unique; //ditto
    result.title = title;
    result.imagePath = path;
    result.resultType = type;
    
    return result;
}

- (id)initWithYTChannelDictionary:(NSDictionary *)channelDict {
    KBYTSearchResult *channel = [KBYTSearchResult new];
    channel.videoId = [channelDict recursiveObjectForKey:@"resourceId"][@"channelId"];
    channel.channelId = channelDict[@"snippet"][@"channelId"];
    channel.title = [channelDict recursiveObjectForKey:@"title"];
    channel.details = [channelDict recursiveObjectForKey:@"description"];
    channel.itemDescription = channel.details;
    channel.stupidId = channelDict[@"id"];
    channel.imagePath = [channelDict recursiveObjectForKey:@"thumbnails"][@"high"][@"url"];
    channel.resultType = kYTSearchResultTypeChannel;
    channel.continuationToken = channelDict[@"nextPageToken"];
    return channel;
}

- (id)initWithYTPlaylistDictionary:(NSDictionary *)playlistDict {
    KBYTSearchResult *playlist = [KBYTSearchResult new];
    playlist.videoId = playlistDict[@"id"];
    playlist.author = playlistDict[@"snippet"][@"channelTitle"];
    playlist.channelId = playlistDict[@"snippet"][@"channelId"];
    playlist.duration = [NSString stringWithFormat:@"%@ tracks", playlistDict[@"contentDetails"][@"itemCount"]];
    playlist.title = [playlistDict recursiveObjectForKey:@"title"];
    playlist.details = [playlistDict recursiveObjectForKey:@"description"];
    playlist.itemDescription = playlist.details;
    playlist.imagePath = [playlistDict recursiveObjectForKey:@"thumbnails"][@"high"][@"url"];
    playlist.resultType = kYTSearchResultTypePlaylist;
    playlist.continuationToken = playlistDict[@"nextPageToken"];
    return playlist;
}

- (KBSection *)sectionRepresentation {
    KBSection *section = [KBSection new];
    section.title = self.title;
    section.infinite = false;
    section.autoScroll = false;
    section.size = @"320x240";
    switch (self.resultType) {
        case kYTSearchResultTypeChannel:
            section.sectionResultType = kYTSearchResultTypeChannel;
            break;
        case kYTSearchResultTypePlaylist:
            section.sectionResultType = kYTSearchResultTypePlaylist;
            break;
        case kYTSearchResultTypeVideo:
            section.sectionResultType = kYTSearchResultTypeVideo;
            break;
        default:
            section.sectionResultType = kYTSearchResultTypeUnknown;
            break;
    }
    section.imagePath = self.imagePath;
    section.uniqueId = self.uniqueID;
    section.subtitle = self.itemDescription;
    section.className = @"KBSection";
    return section;
}

//potentially obsolete
- (id)initWithDictionary:(NSDictionary *)resultDict {
    self = [super init];
    title = resultDict[@"title"];
    author = resultDict[@"author"];
    details = resultDict[@"description"];
    imagePath = resultDict[@"imagePath"];
    videoId = resultDict[@"videoId"];
    duration = resultDict[@"duration"];
    views = resultDict[@"views"];
    age = resultDict[@"age"];
    return self;
}

- (NSString *)readableSearchType {
    switch (self.resultType) {
        case kYTSearchResultTypeUnknown: return @"Unknown";
        case kYTSearchResultTypeVideo: return @"Video";
        case kYTSearchResultTypePlaylist: return @"Playlist";
        case kYTSearchResultTypeChannel: return @"Channel";
        case kYTSearchResultTypeChannelList: return @"Channel List";
        default:
            return @"Unknown";
    }
}
/*
- (NSDictionary *)dictionaryValue {
    if (self.title == nil)self.title = @"Unavailable";
    if (self.details == nil)self.details = @"Unavailable";
    if (self.views == nil)self.views = @"Unavailable";
    if (self.age == nil)self.age = @"Unavailable";
    if (self.author == nil)self.author = @"Unavailable";
    if (self.imagePath == nil)self.imagePath = @"Unavailable";
    if (self.duration == nil)self.duration = @"Unavailable";
    if (self.videoId == nil)self.videoId = @"Unavailable";
    if (self.channelId == nil)self.channelId = @"Unavailable";
    if (self.channelPath == nil)self.channelPath = @"Unavailable";
    return @{@"title": self.title, @"author": self.author, @"details": self.details, @"imagePath": self.imagePath, @"videoId": self.videoId, @"duration": self.duration, @"age": self.age, @"views": self.views, @"resultType": [self readableSearchType], @"channelId": self.channelId, @"channelPath": self.channelPath};
}

- (NSString *)description {
    return [[self dictionaryRepresentation] description];
}
*/
- (NSString *)uniqueID {
    switch (self.resultType) {
        case kYTSearchResultTypeUnknown: return nil;
        case kYTSearchResultTypeVideo: return self.videoId;
        case kYTSearchResultTypePlaylist: return self.playlistId ? self.playlistId : self.videoId;
        case kYTSearchResultTypeChannel: return self.channelId;
        case kYTSearchResultTypeChannelList: return @"Figure out unique id for channel list";
        default:
            return nil;
    }
}

- (NSString *)banner {
    return self.imagePath;
}

@end

/*
 
 KBYTStream identifies an actual playback stream
 
 extension = mp4;
 format = 720p MP4;
 height = 720;
 itag = 22;
 title = "Lil Wayne - No Worries %28Explicit%29 ft. Detail\";
 type = "video/mp4; codecs=avc1.64001F, mp4a.40.2";
 url = "https://r9---sn-bvvbax-2ime.googlevideo.com/videoplayback?dur=229.529&sver=3&expire=1451432986&pl=19&ratebypass=yes&nh=EAE&mime=video%2Fmp4&itag=22&ipbits=0&source=youtube&ms=au&mt=1451411225&mv=m&mm=31&mn=sn-bvvbax-2ime&requiressl=yes&key=yt6&lmt=1429504739223021&id=o-ANaYZmZnobN9YUPpUED-68dQ4O8sFyxHtMaQww4kxgTT&upn=PSfKek6hLJg&gcr=us&sparams=dur%2Cgcr%2Cid%2Cip%2Cipbits%2Citag%2Clmt%2Cmime%2Cmm%2Cmn%2Cms%2Cmv%2Cnh%2Cpl%2Cratebypass%2Crequiressl%2Csource%2Cupn%2Cexpire&fexp=9406813%2C9407016%2C9415422%2C9416126%2C9418404%2C9420452%2C9422596%2C9423662%2C9424205%2C9425382%2C9425742%2C9425965&ip=xx&signature=E0F8B6F26BF082B1EB97509DF597AB175DC04D4D.9408359B27A278F16AEF13EA16DE83AA7A600177\";
 
 the signature deciphering (if necessary) is already taken care of in the url
 
 */


@implementation KBYTStream

- (id)initWithDictionary:(NSDictionary *)streamDict {
    self = [super init];
    
    if ([self processSource:streamDict] == true) {
        return self;
    }
    return nil;
}


- (BOOL)isExpired {
    if ([NSDate passedEpochDateInterval:self.expireTime]) {
        return true;
    }
    return false;
}


/**
 
 take the input dictionary and update our values according to it.
 
 */


- (BOOL)processSource:(NSDictionary *)inputSource {
    //NSLog(@"inputSource: %@", inputSource);
    if ([[inputSource allKeys] containsObject:@"url"]) {
        self.itag = [[inputSource objectForKey:@"itag"] integerValue];
        
        //if you want to limit to mp4 only, comment this if back in
        //  if (fmt == 22 || fmt == 18 || fmt == 37 || fmt == 38)
        //    {
        NSString *url = [[inputSource objectForKey:@"url"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tags = [KBYourTube formatFromTag:self.itag];
        // unsupported format, return nil
        if (tags == nil) {
            return false;
        }
        
        if ([[inputSource valueForKey:@"quality"] length] == 0) {
            self.quality = tags[@"quality"];
        } else {
            self.quality = inputSource[@"quality"];
        }
        self.url = [NSURL URLWithString:url];
        self.expireTime = [[self.url parameterDictionary][@"expire"] integerValue];
        self.format = tags[@"format"]; //@{@"format": @"4K MP4", @"height": @2304, @"extension": @"mp4"}
        self.height = tags[@"height"];
        self.extension = tags[@"extension"];
        if (([self.extension isEqualToString:@"mp4"] || [self.extension isEqualToString:@"3gp"] )) {
            self.playable = true;
        } else {
            self.playable = false;
        }
        
        if (([self.extension isEqualToString:@"m4v"] || [self.extension isEqualToString:@"aac"] )) {
            self.multiplexed = false;
        } else {
            self.multiplexed = true;
        }
        
        self.type = [[[[inputSource valueForKey:@"type"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        self.title = [[[inputSource valueForKey:@"title"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        if (self.height == 0) {
            self.outputFilename = [NSString stringWithFormat:@"%@.%@", self.title,self.extension];
        } else {
            self.outputFilename = [NSString stringWithFormat:@"%@ [%@p].%@", self.title, self.height,self.extension];
        }
        return true;
        // }
    }
    return false;
}

- (NSDictionary *)dictionaryValue {
    if (self.title == nil)self.title = @"Unavailable";
    if (self.type == nil)self.type = @"Unavailable";
    if (self.format == nil)self.format = @"Unavailable";
    if (self.height == nil)self.height = 0;
    if (self.extension == nil)self.extension = @"Unavailable";
    if (self.outputFilename == nil)self.outputFilename = @"Unavailable";
    
    return @{@"title": self.title, @"type": self.type, @"format": self.format, @"height": self.height, @"itag": [NSNumber numberWithInteger:self.itag], @"extension": self.extension, @"url": self.url, @"outputFilename": self.outputFilename};
}

- (NSString *)description {
    return [[self dictionaryValue] description];
}


@end

@implementation YTPlayerItem

@synthesize associatedMedia;

- (double)doubleTime {
    return self.currentTime.value/self.currentTime.timescale;
}

- (double)durationDouble {
    if (self.status != AVPlayerItemStatusReadyToPlay) {
        //DLog(@"status: %lu", self.status);
        return 0;
    }
    return self.duration.value/self.duration.timescale;
}

- (NSString *)description {
    return self.associatedMedia.title;
}

@end

/**
 
 KBYTMedia contains the root reference object to the youtube video queried including the following values
 
 author = LilWayneVEVO;
 duration = 230;
 images =     {
 high = "https://i.ytimg.com/vi/5z25pGEGBM4/hqdefault.jpg";
 medium = "https://i.ytimg.com/vi/5z25pGEGBM4/mqdefault.jpg";
 standard = "https://i.ytimg.com/vi/5z25pGEGBM4/sddefault.jpg";
 };
 keywords = "Lil,Wayne,Detail,Cash,Money,Fear,and,Loathing,in,Las,Vegas,New,Video,explicit,Young,Official";
 streams {} //example of stream listed above
 title = "Lil Wayne - No Worries (Explicit) ft. Detail";
 videoID = 5z25pGEGBM4;
 views = 47109256;
 
 */

@implementation KBYTMedia

- (AVMetadataItem *)metadataItemWithIdentifier:(NSString *)identifier value:(id<NSObject, NSCopying>) value {
    AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc]init];
    item.value = value;
    item.identifier = identifier;
    item.extendedLanguageTag = @"und";
    return [item copy];
}

#if TARGET_OS_TV
- (AVMetadataItem *)metadataArtworkItemWithImage:(UIImage *)image {
    AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc]init];
    item.value = UIImagePNGRepresentation(image);
    item.dataType = (__bridge NSString * _Nullable)(kCMMetadataBaseDataType_PNG);
    item.identifier = AVMetadataCommonIdentifierArtwork;
    item.extendedLanguageTag = @"und";
    return item.copy;
}

#endif



- (YTPlayerItem *)playerItemRepresentation {
    KBYTStream *firstStream = [[self streams] firstObject];
    NSURL *streamURL = firstStream.url;
    //TLog(@"firstStream: %@ in %@", [self streams], NSStringFromSelector(_cmd));
    if (self.hlsManifest) {
        streamURL = [NSURL URLWithString:self.hlsManifest];
        //DLog(@"using streamURL :%@", streamURL);
    }
    YTPlayerItem *mediaItem = [[YTPlayerItem alloc] initWithURL:streamURL];
    mediaItem.associatedMedia = self;
#if TARGET_OS_TV
    NSMutableArray <AVMetadataItem *> *allItems = [NSMutableArray new];
    [allItems addObject:[self metadataItemWithIdentifier:AVMetadataCommonIdentifierTitle value:self.title]];
    [allItems addObject:[self metadataItemWithIdentifier:AVMetadataCommonIdentifierDescription value:self.details]];
    [allItems addObject:[self metadataItemWithIdentifier:AVMetadataIdentifierQuickTimeMetadataArtist value:self.author]];
  
    
   
    NSString *artworkPath = self.images[@"medium"];
    if (artworkPath == nil)
        artworkPath = self.images[@"standard"];
    if (artworkPath == nil)
        artworkPath = self.images[@"high"];
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:artworkPath]];
    UIImage *theImage = [UIImage imageWithData:imageData];
    [allItems addObject:[self metadataArtworkItemWithImage:theImage]];
    
    mediaItem.externalMetadata = allItems;
#endif
    return mediaItem;
}

- (BOOL)isExpired {
    if ([NSDate passedEpochDateInterval:self.expireTime]) {
        return true;
    }
    return false;
}

//make sure if its an adaptive stream that we match the video streams with the proper audio stream.

- (void)matchAudioStreams {
    KBYTStream *audioStream = [[self.streams filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"itag == 140"]]lastObject];
    for (KBYTStream *theStream in self.streams) {
        if ([theStream multiplexed] == false && theStream != audioStream)
        {
            //NSLog(@"adding audio stream to stream with itag: %lu", (long)theStream.itag);
            [theStream setAudioStream:audioStream];
        }
    }
}

- (id)initWithDictionary:(NSDictionary *)inputDict {
    self = [super init];
    if ([self processDictionary:inputDict] == true) {
        return self;
    }
    return nil;
}


- (id)initWithJSON:(NSDictionary *)jsonDict error:(NSError * __autoreleasing *)outError {
    self = [super init];
    if ([self processJSON:jsonDict error:outError] == true) {
        return self;
    }
    return nil;
}

- (BOOL)processJSON:(NSDictionary *)jsonDict error:(NSError * __autoreleasing *)outError {
    NSDictionary *streamingData = jsonDict[@"streamingData"];
    NSDictionary *videoDetails = jsonDict[@"videoDetails"];
    NSDictionary *playabilityStatus = jsonDict[@"playabilityStatus"];
    NSString *status = playabilityStatus[@"status"];
    if (![[status lowercaseString] isEqualToString:@"ok"]){
        DLog(@"%@ failed because reason: %@",jsonDict, playabilityStatus[@"reason"]);
        NSDictionary *dict = @{NSLocalizedDescriptionKey: playabilityStatus[@"reason"]};
        if (outError) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:42 userInfo:dict];
        }
        return false;
    }
    self.author = videoDetails[@"author"];
    self.title = videoDetails[@"title"];
    self.videoId = videoDetails[@"videoId"];
    self.views = videoDetails[@"viewCount"];
    self.duration = videoDetails[@"lengthSeconds"];
    self.details = videoDetails[@"shortDescription"];
    self.hlsManifest = streamingData[@"hlsManifestUrl"];
    self.playlistId = [jsonDict recursiveObjectForKey:@"playlistId"];
    self.channelId = [videoDetails recursiveObjectForKey:@"channelId"];
    NSArray *imageArray = videoDetails[@"thumbnail"][@"thumbnails"];
    self.keywords = [videoDetails[@"keywords"] componentsJoinedByString:@","];
    if (!self.keywords){
        self.keywords = @"";
    }
    NSMutableDictionary *images = [NSMutableDictionary new];
    NSInteger imageCount = imageArray.count; //TODO make sure there are actually that many images
    images[@"high"] = imageArray.lastObject[@"url"];
    images[@"medium"] = imageArray[imageCount-1][@"url"];
    //images[@"standard"] = imageArray[imageCount-3][@"url"];
    self.images = images;
    NSMutableArray *videoArray = [NSMutableArray new];
    NSArray *formats = streamingData[@"formats"];
    //NSLog(@"adaptiveFormats: %@", adaptiveFormats);
    //NSLog(@"formats: %@", formats);
    
    NSArray *adaptiveFormats = streamingData[@"adaptiveFormats"];
    [adaptiveFormats enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *videoDict = [obj mutableCopy];
        //add the title from the previous dictionary created
        [videoDict setValue:self.title forKey:@"title"];
        //NSLog(@"videoDict: %@", videoDict);
        //process the raw dictionary into something that can be used with download links and format details
        KBYTStream *processed = [[KBYTStream alloc] initWithDictionary:videoDict];
        //NSDictionary *processed = [self processSource:videoDict];
        if (processed.title != nil)
        {
            self.expireTime = [processed expireTime];
            //if we actually have a video detail dictionary add it to final array
            [videoArray addObject:processed];
        }
    }];
    [formats enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *videoDict = [obj mutableCopy];
        //add the title from the previous dictionary created
        [videoDict setValue:self.title forKey:@"title"];
        //NSLog(@"videoDict: %@", videoDict);
        //process the raw dictionary into something that can be used with download links and format details
        KBYTStream *processed = [[KBYTStream alloc] initWithDictionary:videoDict];
        //NSDictionary *processed = [self processSource:videoDict];
        if (processed.title != nil)
        {
            self.expireTime = [processed expireTime];
            //if we actually have a video detail dictionary add it to final array
            [videoArray addObject:processed];
        }
    }];
    //NSLog(@"videoArray: %@", videoArray);
    self.streams = videoArray;
    [self matchAudioStreams];
    return true;
}

//take the raw video detail dictionary, update our object and find/update stream details

- (BOOL)processDictionary:(NSDictionary *)vars {
    //grab the raw streams string that is available for the video
    NSString *streamMap = [vars objectForKey:@"url_encoded_fmt_stream_map"];
    NSString *adaptiveMap = [vars objectForKey:@"adaptive_fmts"];
    //grab a few extra variables from the vars
    
    NSString *title = [vars[@"title"] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    NSString *author = [[vars[@"author"] stringByReplacingOccurrencesOfString:@"+" withString:@" "]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    NSString *iurlhq = [vars[@"iurlhq"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *iurlmq = [vars[@"iurlmq"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *iurlsd = [vars[@"iurlsd"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *keywords = [[vars[@"keywords"] stringByReplacingOccurrencesOfString:@"+" withString:@" "]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    NSString *duration = vars[@"length_seconds"];
    NSString *videoID = vars[@"video_id"];
    NSNumberFormatter *numFormatter = [NSNumberFormatter new];
    numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    NSNumber *view_count = [numFormatter numberFromString:vars[@"view_count"]];
    
    //unfortunately get_video_info doesn't include video descriptions, thankfully
    //none of this is ever called on the mainthread so a little extra minor call here
    //doesn't add much overhead and doesn't need a separate block call
    NSString *desc = [[KBYourTube sharedInstance] videoDescription:videoID];
    if (desc != nil) {
        self.details = desc;
    }
    
    self.title = [title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.author = author;
    NSMutableDictionary *images = [NSMutableDictionary new];
    if (iurlhq != nil)
        images[@"high"] = iurlhq;
    if (iurlmq != nil)
        images[@"medium"] = iurlmq;
    if (iurlsd != nil)
        images[@"standard"] = iurlsd;
    self.images = images;
    self.keywords = keywords;
    self.duration = duration;
    self.videoId = videoID;
    self.views = [numFormatter stringFromNumber:view_count];
    if (self.keywords == nil){
        self.keywords = @"";
    }
    if (self.views == nil){
        self.views = @"";
    }
    //separate the streams into their initial array
    
    // NSLog(@"StreamMap: %@", streamMap);
    
    NSArray *maps = [[streamMap stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] componentsSeparatedByString:@","];
    NSMutableArray *videoArray = [NSMutableArray new];
    for (NSString *map in maps ) {
        //same thing, take these raw feeds and make them into an NSDictionary with usable info
        NSMutableDictionary *videoDict = [self parseFlashVars:map];
        //add the title from the previous dictionary created
        [videoDict setValue:title forKey:@"title"];
        //process the raw dictionary into something that can be used with download links and format details
        KBYTStream *processed = [[KBYTStream alloc] initWithDictionary:videoDict];
        //NSDictionary *processed = [self processSource:videoDict];
        if (processed.title != nil)
        {
            self.expireTime = [processed expireTime];
            //if we actually have a video detail dictionary add it to final array
            [videoArray addObject:processed];
        }
    }
    
    //adaptive streams, the higher res stuff (1080p, 1440p, 4K) all generally reside here.
    
    NSArray *adaptiveMaps = [[adaptiveMap stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] componentsSeparatedByString:@","];
    for (NSString *amap in adaptiveMaps ) {
        //same thing, take these raw feeds and make them into an NSDictionary with usable info
        NSMutableDictionary *videoDict = [self parseFlashVars:amap];
        //  NSLog(@"videoDict: %@", videoDict[@"itag"]);
        //add the title from the previous dictionary created
        [videoDict setValue:[title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:@"title"];
        //process the raw dictionary into something that can be used with download links and format details
        KBYTStream *processed = [[KBYTStream alloc] initWithDictionary:videoDict];
        if (processed.title != nil)
        {
            //if we actually have a video detail dictionary add it to final array
            [videoArray addObject:processed];
        }
    }
    
    
    self.streams = videoArray;
    
    //adaptive streams aren't multiplexed, so we need to match the audio with the video
    
    [self matchAudioStreams];
    
    return TRUE;
    
}

- (NSString *)expiredString {
    if ([self isExpired]) return @"YES";
    return @"NO";
}

- (NSDictionary *)dictionaryRepresentation {
    if (self.details == nil)self.details = @"Unavailable";
    if (self.keywords == nil)self.keywords = @"Unavailable";
    if (self.views == nil)self.views = @"Unavailable";
    if (self.duration == nil)self.duration = @"Unavailable";
    if (self.title == nil)self.title = @"Unavailable";
    if (self.images == nil)self.images = @{};
    if (self.streams == nil)self.streams = @[];
    if (self.hlsManifest == nil) self.hlsManifest = @"Unavailable";
    return @{@"title": self.title, @"author": self.author, @"keywords": self.keywords, @"videoID": self.videoId, @"views": self.views, @"duration": self.duration, @"images": self.images, @"streams": self.streams, @"details": self.details, @"expireTime": [NSNumber numberWithInteger:self.expireTime], @"isExpired": [self expiredString],@"hlsManifest":  self.hlsManifest};
}

- (NSString *)description {
    return [[self dictionaryRepresentation] description];
}

@end


/**
 
 Meat and potatoes of yourTube, get video details / signature deciphering and helper functions to mux / fix/extract/adjust audio
 
 most things are done through the singleton method.
 
 */

@implementation KBYourTube

@synthesize ytkey, yttimestamp, deviceController, airplayIP, lastSearch, userDetails;

#pragma mark convenience methods

- (void)startReachabilityMonitoring {
    AFNetworkReachabilityManager *man = [AFNetworkReachabilityManager sharedManager];
    [man setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
            TLog(@"wifi reachable");
        } else {
            TLog(@"wifi is not reachable");
        }
    }];
    [man startMonitoring];
    
}

- (void)stopReachabilityMonitoring {
    AFNetworkReachabilityManager *man = [AFNetworkReachabilityManager sharedManager];
    [man setReachabilityStatusChangeBlock:nil];
    [man stopMonitoring];
}

- (void)postHomeDataChangedNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:KBYTHomeDataChangedNotification object:nil];
}

- (void)postUserDataChangedNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:KBYTUserDataChangedNotification object:nil];
}

- (void)removeHomeSection:(MetaDataAsset *)asset {
    //NSMutableDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile:[self newSectionsFile]] mutableCopy];
    //NSMutableArray *sections = [dict[@"sections"] mutableCopy];
    //NSDictionary *item = [[sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"channel == %@", asset.uniqueID]] firstObject];
    NSMutableArray *sections = [[[NSArray alloc] initWithContentsOfFile:[self newSectionsFile]] mutableCopy];
    NSDictionary *item = [[sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uniqueId == %@", asset.uniqueID]] firstObject];
    TLog(@"found item: %@", item);
    [sections removeObject:item];
    [sections writeToFile:[self newSectionsFile] atomically:true];
    [self postHomeDataChangedNotification];
    
}

- (void)oldremoveHomeSection:(MetaDataAsset *)asset {
    NSMutableDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile:[self sectionsFile]] mutableCopy];
    NSMutableArray *sections = [dict[@"sections"] mutableCopy];
    NSDictionary *item = [[sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"channel == %@", asset.uniqueID]] firstObject];
    TLog(@"found item: %@", item);
    [sections removeObject:item];
    dict[@"sections"] = sections;
    [dict writeToFile:[self sectionsFile] atomically:true];
    [self postHomeDataChangedNotification];
    
}

- (void)oldsetFeaturedResult:(KBYTSearchResult *)channel {
    NSMutableDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile:[self sectionsFile]] mutableCopy];
    dict[@"featured"] = channel.videoId;
    [dict writeToFile:[self sectionsFile] atomically:true];
    [self postHomeDataChangedNotification];
}

- (void)setFeaturedResult:(KBYTSearchResult *)channel {
    NSMutableArray *sections = [[[NSArray alloc] initWithContentsOfFile:[self newSectionsFile]] mutableCopy];
    KBSection *newItem = [KBSection new];
    newItem.title = channel.title;
    newItem.uniqueId = channel.videoId;
    newItem.imagePath = channel.imagePath;
    newItem.subtitle = channel.itemDescription;
    newItem.type = @"banner";
    newItem.infinite = false;
    newItem.autoScroll = false;
    newItem.size = @"640x480";
    newItem.className = @"KBSection";
    newItem.sectionResultType = kYTSearchResultTypeChannel;
    TLog(@"setting featured: %@", newItem);
    NSDictionary *dictRep = [newItem dictionaryRepresentation];
    TLog(@"dictionaryRepresentation: %@", dictRep);
    //NSDictionary *currentFeatured = [sections firstObject];
    [sections removeObjectAtIndex:0];
    TLog(@"sections: %@", sections);
    [sections insertObject:dictRep atIndex:0];
    [sections writeToFile:[self newSectionsFile] atomically:true];
    [self postHomeDataChangedNotification];
}

- (void)addHomeSection:(KBYTSearchResult *)channel {
    TLog(@"channel: %@", channel);
    NSMutableArray *sections = [[[NSArray alloc] initWithContentsOfFile:[self newSectionsFile]] mutableCopy];
    NSDictionary *item = [[sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"uniqueID == %@", channel.videoId]] firstObject];
    if (item) {
        TLog(@"already found!");
        return;
    }
    KBSection *newItem = [KBSection new];
    newItem.title = channel.title;
    newItem.uniqueId = channel.videoId;
    newItem.imagePath = channel.imagePath;
    newItem.subtitle = channel.itemDescription;
    newItem.type = @"standard";
    newItem.infinite = false;
    newItem.autoScroll = false;
    newItem.size = @"320x240";
    newItem.className = @"KBSection";
    newItem.sectionResultType = kYTSearchResultTypeChannel;
    //NSDictionary *newItem = @{@"name": channel.title, @"channel": channel.videoId, @"imagePath": channel.imagePath, @"description": channel.itemDescription};
    TLog(@"adding new item: %@", newItem);
    NSDictionary *dictRep = [newItem dictionaryRepresentation];
    TLog(@"dictionaryRepresentation: %@", dictRep);
    [sections addObject:dictRep];
    TLog(@"sections: %@", sections);
    [sections writeToFile:[self newSectionsFile] atomically:true];
    [self postHomeDataChangedNotification];
}

- (void)addHomeSectionold:(KBYTSearchResult *)channel {
    TLog(@"channel: %@", channel);
    NSMutableDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile:[self sectionsFile]] mutableCopy];
    NSMutableArray *sections = [dict[@"sections"] mutableCopy];
    NSDictionary *item = [[sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"channel == %@", channel.videoId]] firstObject];
    if (item) {
        TLog(@"already found!");
        return;
    }
    NSDictionary *newItem = @{@"name": channel.title, @"channel": channel.videoId, @"imagePath": channel.imagePath, @"description": channel.itemDescription};
    TLog(@"adding new item: %@", newItem);
    //TLog(@"itemDesc: %@", channel.itemDescription);
    [sections addObject:newItem];
    dict[@"sections"] = sections;
    TLog(@"sections: %@", sections);
    [dict writeToFile:[self sectionsFile] atomically:true];
    [self postHomeDataChangedNotification];
}

- (NSString *)newSectionsFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"newsections.plist"];
}

- (NSString *)sectionsFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"sections.plist"];
}

/*
 name: YouTube
 image: https://yt3.ggpht.com/584JjRp5QMuKbyduM_2k5RlXFqHJtQ0qLIPZpwbUjMJmgzZngHcam5JMuZQxyzGMV5ljwJRl0Q=s900-c-k-c0x00ffffff-no-rj
 banner: https://yt3.ggpht.com/uxTVoONZDHfInEuR4Uspk-rtR_eqBAbmaOj2-xgXhs1I87k_QKaNqFOLkhB2omQp2C74vgNx=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj
 name: Sports
 image: https://yt3.ggpht.com/Q4LNAquvFLgrqCSuKglF_EF3wghkG5AyutxrlMAFGctQn8rFZFAg-AhDaaci0tWYUBwLya1C5A=s176-c-k-c0x00ffffff-no-rj-mo
 banner: (null)
 2022-06-11 15:33:52.093307-0700 yourTube[2278:40123] channels count: 12
 name: Gaming
 image: https://yt3.ggpht.com/drsoZuCe8u-2JarqCZ-Z9oJh4Td5t1faAMjrOVSjjDpPX27Os0qLWNiGOuS-973r7jKU65L5IA=s176-c-k-c0x00ffffff-no-rj-mo
 banner: (null)
 2022-06-11 15:33:52.208370-0700 yourTube[2278:40123] channels count: 12
 name: Fashion & Beauty
 image: https://yt3.ggpht.com/Cw_5o8wcghBvDl-oCq9-ehGBezoxo3gOdz2yE5jt74ZdAWpvH6UyADqtQLxql9Ud_NRU4sYV4g=s176-c-k-c0x00ffffff-no-rj-mo
 banner: (null)
 name: Music
 image: https://yt3.ggpht.com/nCOmA7RfWNA-UU-4HsTXkWt2LWZHvU-3E2sHc-vJV0H981_J5oH8zmnisUjElCMUni-nDrbvwOU=s176-c-k-c0x00ffffff-no-rj-mo
 banner: (null)
 2022-06-11 15:33:52.354633-0700 yourTube[2278:40115] channels count: 7
 name: Popular on YouTube
 image: https://yt3.ggpht.com/_lhig9VVBeYLLZ0uEDUdoQsOBiGmWh8LxEB3VStXiBP3Xw2_HaFUldbGP_BEBVpBBJogHTA_eA=s900-c-k-c0x00ffffff-no-rj
 banner: https://yt3.ggpht.com/ihYyB3RUEhSjt5Pn7IwTjh1Pv4KouGOzYL51-Dk_cvGH_f2WkuL7as0kV1J091afqb5Fg8rz1Q=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj
 name: Virtual Reality
 image: https://yt3.ggpht.com/qmYIeA3vVO5m2dmSgL1n3VR2QNmcFhmurVRhxy_wQ6jGd35OoVFnwWrUf0Wn-_TrJ88s-jWX1EM=s900-c-k-c0x00ffffff-no-rj
 banner: https://yt3.ggpht.com/5VQ4RrTfG7iC2xoPdMwKw1950v8SvuP8lEZiVjjqxlpOMIBEMP7RXCPnBxR-rvwaTSPuvHj-=w2560-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj
 */

- (NSArray <KBSection*>*)createDefaultSectionsArray {
    KBSection *spotlight = [[KBSection alloc] init];
    spotlight.title = @"YouTube Spotlight";
    spotlight.type = @"banner";
    spotlight.size = @"640x480";
    spotlight.infinite = false;
    spotlight.autoScroll = false;
    spotlight.sectionResultType = kYTSearchResultTypeChannel;
    spotlight.order = 0;
    spotlight.className = @"KBSection";
    spotlight.uniqueId = KBYTSpotlightChannelID;
    spotlight.subtitle = @"YouTube's Official Channel helps you discover what's new & trending globally. Watch must-see videos, from music to culture to Internet phenomena";
    spotlight.imagePath = @"https://yt3.googleusercontent.com/584JjRp5QMuKbyduM_2k5RlXFqHJtQ0qLIPZpwbUjMJmgzZngHcam5JMuZQxyzGMV5ljwJRl0Q=s160-c-k-c0x00ffffff-no-rj";
    
    KBSection *popular = [KBSection new];
    popular.type = @"standard";
    popular.size = @"320x240";
    popular.infinite = false;
    popular.autoScroll = false;
    popular.sectionResultType = kYTSearchResultTypeChannel;
    popular.order = 1;
    popular.className = @"KBSection";
    popular.title = @"Popular on YouTube";
    popular.uniqueId = KBYTPopularChannelID;
    popular.subtitle = @"The pulse of what's popular on YouTube. Check out the latest music videos, trailers, comedy clips, and everything else that people are watching right now.";
    popular.imagePath = @"https://yt3.ggpht.com/_lhig9VVBeYLLZ0uEDUdoQsOBiGmWh8LxEB3VStXiBP3Xw2_HaFUldbGP_BEBVpBBJogHTA_eA=s900-c-k-c0x00ffffff-no-rj";
    
    
    KBSection *music = [KBSection new];
    music.type = @"standard";
    music.size = @"320x240";
    music.infinite = false;
    music.autoScroll = false;
    music.sectionResultType = kYTSearchResultTypeChannel;
    music.order = 2;
    music.title = @"Music";
    music.uniqueId = KBYTMusicChannelID;
    music.className = @"KBSection";
    music.subtitle = @"Visit the YouTube Music Channel to find today’s top talent, featured artists, and playlists. Subscribe to see the latest in the music world.\nThis channel was generated automatically by YouTube's video discovery system.";
    music.imagePath = @"https://yt3.ggpht.com/nCOmA7RfWNA-UU-4HsTXkWt2LWZHvU-3E2sHc-vJV0H981_J5oH8zmnisUjElCMUni-nDrbvwOU=s900-c-k-c0x00ffffff-no-rj-mo";
    
    KBSection *sports = [KBSection new];
    sports.type = @"standard";
    sports.size = @"320x240";
    sports.infinite = false;
    sports.autoScroll = false;
    sports.sectionResultType = kYTSearchResultTypeChannel;
    sports.order = 3;
    sports.title = @"Sports";
    sports.className = @"KBSection";
    sports.uniqueId = KBYTSportsChannelID;
    sports.subtitle = @"YouTube's featured Sports channel.";
    sports.imagePath = @"https://yt3.ggpht.com/Q4LNAquvFLgrqCSuKglF_EF3wghkG5AyutxrlMAFGctQn8rFZFAg-AhDaaci0tWYUBwLya1C5A=s900-c-k-c0x00ffffff-no-rj-mo";
    
    KBSection *gaming = [KBSection new];
    gaming.type = @"standard";
    gaming.size = @"320x240";
    gaming.infinite = false;
    gaming.autoScroll = false;
    gaming.sectionResultType = kYTSearchResultTypeChannel;
    gaming.order = 4;
    gaming.title = @"Gaming";
    gaming.className = @"KBSection";
    gaming.uniqueId = KBYTGamingChannelID;
    gaming.subtitle = @"YouTube's featured Gaming channel.";
    gaming.imagePath = @"https://yt3.ggpht.com/drsoZuCe8u-2JarqCZ-Z9oJh4Td5t1faAMjrOVSjjDpPX27Os0qLWNiGOuS-973r7jKU65L5IA=s900-c-k-c0x00ffffff-no-rj-mo";
    
    KBSection *fb = [KBSection new];
    fb.type = @"standard";
    fb.size = @"320x240";
    fb.infinite = false;
    fb.autoScroll = false;
    fb.sectionResultType = kYTSearchResultTypeChannel;
    fb.order = 5;
    fb.title = @"Fashion & Beauty";
    fb.className = @"KBSection";
    fb.uniqueId = KBYTFashionAndBeautyID;
    fb.subtitle = @"YouTube's featured Fashion & Beauty channel.";
    fb.imagePath = @"https://yt3.ggpht.com/Cw_5o8wcghBvDl-oCq9-ehGBezoxo3gOdz2yE5jt74ZdAWpvH6UyADqtQLxql9Ud_NRU4sYV4g=s900-c-k-c0x00ffffff-no-rj-mo";

    KBSection *vr = [KBSection new];
    vr.type = @"standard";
    vr.size = @"320x240";
    vr.infinite = false;
    vr.autoScroll = false;
    vr.sectionResultType = kYTSearchResultTypeChannel;
    vr.order = 6;
    vr.title = @"Virtual Reality";
    vr.className = @"KBSection";
    vr.uniqueId = KBYT360ChannelID;
    vr.subtitle = @"Learn more at https://vr.youtube.com";
    vr.imagePath = @"https://yt3.ggpht.com/Cw_5o8wcghBvDl-oCq9-ehGBezoxo3gOdz2yE5jt74ZdAWpvH6UyADqtQLxql9Ud_NRU4sYV4g=s900-c-k-c0x00ffffff-no-rj-mo";
    
    return @[spotlight, popular, music, sports, gaming, fb, vr];
}

- (NSDictionary *)createDefaultSections {
    
    NSArray *items = @[@{@"name": @"Popular on YouTube",
                         @"channel": KBYTPopularChannelID,
                         @"description": @"The pulse of what's popular on YouTube. Check out the latest music videos, trailers, comedy clips, and everything else that people are watching right now.",
                         @"imagePath": @"https://yt3.ggpht.com/_lhig9VVBeYLLZ0uEDUdoQsOBiGmWh8LxEB3VStXiBP3Xw2_HaFUldbGP_BEBVpBBJogHTA_eA=s900-c-k-c0x00ffffff-no-rj"},
                       
                       @{@"name": @"Music",
                         @"channel": KBYTMusicChannelID,
                         @"description": @"Visit the YouTube Music Channel to find today’s top talent, featured artists, and playlists. Subscribe to see the latest in the music world.\nThis channel was generated automatically by YouTube's video discovery system.",
                         @"imagePath": @"https://yt3.ggpht.com/nCOmA7RfWNA-UU-4HsTXkWt2LWZHvU-3E2sHc-vJV0H981_J5oH8zmnisUjElCMUni-nDrbvwOU=s900-c-k-c0x00ffffff-no-rj-mo"},
                       
                       @{@"name": @"Sports",
                         @"channel": KBYTSportsChannelID,
                         @"description": @"YouTube's featured Sports channel.",
                         @"imagePath": @"https://yt3.ggpht.com/Q4LNAquvFLgrqCSuKglF_EF3wghkG5AyutxrlMAFGctQn8rFZFAg-AhDaaci0tWYUBwLya1C5A=s900-c-k-c0x00ffffff-no-rj-mo"},
                       
                       @{@"name": @"Gaming",
                         @"channel": KBYTGamingChannelID,
                         @"description": @"YouTube's featured Gaming channel.",
                         @"imagePath": @"https://yt3.ggpht.com/drsoZuCe8u-2JarqCZ-Z9oJh4Td5t1faAMjrOVSjjDpPX27Os0qLWNiGOuS-973r7jKU65L5IA=s900-c-k-c0x00ffffff-no-rj-mo"},
                       
                       @{@"name": @"Fashion & Beauty",
                         @"channel": KBYTFashionAndBeautyID,
                         @"description": @"YouTube's featured Fashion & Beauty channel.",
                         @"imagePath": @"https://yt3.ggpht.com/Cw_5o8wcghBvDl-oCq9-ehGBezoxo3gOdz2yE5jt74ZdAWpvH6UyADqtQLxql9Ud_NRU4sYV4g=s900-c-k-c0x00ffffff-no-rj-mo"},
                       /*
                       @{@"name": @"YouTube",
                         @"channel": KBYTSpotlightChannelID,
                         @"description": @"YouTube's Official Channel helps you discover what's new & trending globally. Watch must-see videos, from music to culture to Internet phenomena.",
                         @"imagePath": @"https://yt3.ggpht.com/584JjRp5QMuKbyduM_2k5RlXFqHJtQ0qLIPZpwbUjMJmgzZngHcam5JMuZQxyzGMV5ljwJRl0Q=s900-c-k-c0x00ffffff-no-rj"},
                       */
                       @{@"name": @"Virtual Reality",
                         @"channel": KBYT360ChannelID,
                         @"description": @"Learn more at https://vr.youtube.com",
                         @"imagePath": @"https://yt3.ggpht.com/qmYIeA3vVO5m2dmSgL1n3VR2QNmcFhmurVRhxy_wQ6jGd35OoVFnwWrUf0Wn-_TrJ88s-jWX1EM=s900-c-k-c0x00ffffff-no-rj"},
                       
    ];
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"sections"] = items;
    dict[@"featured"] = KBYTSpotlightChannelID;//@"UCByOQJjav0CUDwxCk-jVNRQ";
    return dict;
}

- (void)resetHomeScreenToDefaults {
    [FM removeItemAtPath:[self newSectionsFile] error:nil];
    [self homeScreenData]; //write the new data
    [self postHomeDataChangedNotification];
}

- (void)resetHomeScreenToDefaultsold {
    [FM removeItemAtPath:[self sectionsFile] error:nil];
    [self homeScreenData]; //write the new data
    [self postHomeDataChangedNotification];
}

- (NSArray *)homeScreenData {
    if ([FM fileExistsAtPath:[self newSectionsFile]]) {
        TLog(@"loading from saved file");
        return [NSArray arrayWithContentsOfFile:[self newSectionsFile]];
    }
    NSArray *def = [[self createDefaultSectionsArray] convertArrayToDictionaries];
    [def writeToFile:[self newSectionsFile] atomically:true];
    return def;
}

- (NSDictionary *)homeScreenDataold {
    if ([FM fileExistsAtPath:[self sectionsFile]]) {
        TLog(@"loading from saved file");
        return [NSDictionary dictionaryWithContentsOfFile:[self sectionsFile]];
    }
    NSDictionary *def = [self createDefaultSections];
    [def writeToFile:[self sectionsFile] atomically:true];
    return def;
}

+ (NSUserDefaults *)sharedUserDefaults {
    static dispatch_once_t pred;
    static NSUserDefaults* shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.nito.tuyuTV"];
    });
    
    return shared;
}

- (NSString *)userDetailsCache {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"user.plist"];
}

- (BOOL)loadUserDetailsFromCache {
    if (![FM fileExistsAtPath:[self userDetailsCache]]) return FALSE;
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[self userDetailsCache]];
    self.userDetails = [dict convertDictionaryToObjects];
    return true;
}

- (void)cacheUserDetails {
    NSArray *newResults = [self.userDetails[@"results"] convertArrayToDictionaries];
    NSArray *channels = [self.userDetails[@"channels"] convertArrayToDictionaries];
    NSMutableDictionary *_newDict = [self.userDetails mutableCopy];
    _newDict[@"results"] = newResults;
    _newDict[@"channels"] = channels;
    BOOL writeUserDeets = [_newDict writeToFile:[self userDetailsCache] atomically:true];
    if (writeUserDeets) {
        TLog(@"user deets written successfully!");
    } else {
        TLog(@"user deets write failed!");
    }
    [[KBYourTube sharedUserDefaults] setObject:_newDict forKey:@"testKey"];
}

- (void)addChannelToUserDetails:(KBYTSearchResult *)channel {
    NSMutableArray *channels = [self.userDetails[@"channels"] mutableCopy];
    if (!channels){
        channels = [NSMutableArray new];
    }
    [channels insertObject:channel atIndex:0];//add it to the front/top.
    [(NSMutableDictionary*)self.userDetails setObject:channels forKey:@"channels"];
    
}

- (NSString *)nextURL {
    return @"https://www.youtube.com/youtubei/v1/next?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8";
}

- (NSString *)searchURL {
    return @"https://www.youtube.com/youtubei/v1/search?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8";
}

- (NSString *)playerURL {
    return @"https://www.youtube.com/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8";
}

- (NSString *)browseURL {
    return @"https://www.youtube.com/youtubei/v1/browse?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8";
}

// '{ videoId = xpVfcZ0ZcFM, contentCheckOk = True, racyCheckOk = True, context = { client = { clientName = ANDROID, clientScreen = , clientVersion = 16.46.37, hl = en, gl = US, utcOffsetMinutes = 0 }, thirdParty = { embedUrl = https://www.youtube.com } } }'


- (NSDictionary *)paramsForChannelID:(NSString *)channelID continuation:(NSString *)continuationToken {
    if (continuationToken == nil) {
     return @{ @"browseId": channelID,
               @"context":  @{ @"client":
                                   @{ @"clientName": @"WEB",
                                      @"clientVersion": @"2.20210408.08.00",
                                      @"hl": @"en",
                                      @"gl": @"US",
                                      @"utcOffsetMinutes": @0 } } };
    }
    return @{ @"browseId": channelID,
              @"continuation": continuationToken,
              @"context":  @{ @"client":
                                  @{ @"clientName": @"WEB",
                                     @"clientVersion": @"2.20210408.08.00",
                                     @"hl": @"en",
                                     @"gl": @"US",
                                     @"utcOffsetMinutes": @0 } } };
}

- (NSDictionary *)paramsForChannelID:(NSString *)channelID {
    return [self paramsForChannelID:channelID continuation:nil];
}

- (NSDictionary *)paramsForPlaylist:(NSString *)playlistID continuation:(NSString *)continuationToken {
    if (continuationToken == nil) continuationToken = @"";
    return @{ @"playlistId": playlistID,
              @"continuation": continuationToken,
              @"context":  @{ @"client":
                                  @{ @"clientName": @"WEB",
                                     @"clientVersion": @"2.20210408.08.00",
                                     @"hl": @"en",
                                     @"gl": @"US",
                                     @"utcOffsetMinutes": @0 } } };
}

- (NSDictionary *)paramsForPlaylist:(NSString *)playlistID {
    return [self paramsForPlaylist:playlistID continuation:nil];
}

- (NSDictionary *)iosParamsForVideo:(NSString *)videoID {
    return @{ @"videoId": videoID,
              @"contentCheckOk": @"True",
              @"racyCheckOk": @"True",
              @"REQUIRE_JS_PLAYER": @"False",
              @"INNERTUBE_CONTEXT_CLIENT_NAME": @5,
              @"context":  @{ @"client":
                                  @{ @"clientName": @"IOS",
                                     @"clientVersion": @"19.29.1",
                                     @"deviceMake": @"Apple",
                                     @"deviceModel": @"iPhone16,2",
                                     @"userAgent": @"com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)",
                                     @"osName": @"iPhone",
                                     @"osVersion": @"17.5.1.21F90",
                                     @"hl": @"en",
                                     @"gl": @"US",
                                     @"utcOffsetMinutes": @0 },
                              @"thirdParty": @{ @"embedUrl": @"https://www.youtube.com" } },
              @"playbackContext": @{@"contentPlaybackContext": @{@"html5Preference": @"HTML5_PREF_WANTS"}}
    };
}

- (NSDictionary *)webparamsForVideo:(NSString *)videoID {
    return [self iosParamsForVideo:videoID];
    return @{ @"videoId": videoID,
              @"contentCheckOk": @"true",
              @"racyCheckOk": @"true",
              @"REQUIRE_JS_PLAYER": @"False",
              @"context":  @{ @"client":
                                  @{ @"clientName": @"WEB",
                                     @"clientVersion": @"2.20240726.00.00",
                                     @"userAgent": @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15,gzip(gfe)",
                                     @"hl": @"en",
                                     @"gl": @"US",
                                     @"utcOffsetMinutes": @0 },
                              @"thirdParty": @{ @"embedUrl": @"https://www.youtube.com" } },
              @"playbackContext": @{@"contentPlaybackContext": @{@"html5Preference": @"HTML5_PREF_WANTS"}}
              
    };
}

- (NSDictionary *)paramsForVideo:(NSString *)videoID {
    return [self webparamsForVideo:videoID];
    return @{ @"videoId": videoID,
              @"contentCheckOk": @"true",
              @"racyCheckOk": @"true",
              @"context":  @{ @"client":
                                  @{ @"clientName": @"ANDROID",
                                     @"clientVersion": @"16.46.37",
                                     @"hl": @"en",
                                     @"gl": @"US",
                                     @"utcOffsetMinutes": @0 },
                              @"thirdParty": @{ @"embedUrl": @"https://www.youtube.com" } } };
}

- (NSDictionary *)paramsForSearch:(NSString *)query {
    return [self paramsForSearch:query forType:KBYTSearchTypeAll continuation:nil];
}

- (NSString *)paramForType:(KBYTSearchType)type {
    switch (type) {
        case KBYTSearchTypeAll: return @"";
        case KBYTSearchTypeVideos: return @"EgIQAQ%3D%3D";
        case KBYTSearchTypePlaylists: return @"EgIQAw%3D%3D";
        case KBYTSearchTypeChannels: return @"EgIQAg%3D%3D";
        default:
            break;
    }
    return nil;
}

- (NSDictionary *)paramsForSearch:(NSString *)query forType:(KBYTSearchType)type continuation:(NSString *)continuationToken {
    if (continuationToken == nil) continuationToken = @"";
    return @{ @"query": query,
              @"params": [self paramForType:type],
              @"continuation": continuationToken,
              @"context":  @{ @"client":
                                  @{ @"clientName": @"WEB",
                                     @"clientVersion": @"2.20210408.08.00",
                                     @"hl": @"en",
                                     @"gl": @"US",
                                     @"utcOffsetMinutes": @0 } } };
}

+ (YTSearchResultType)resultTypeForString:(NSString *)string {
    if ([string isEqualToString:@"Channel"]) return kYTSearchResultTypeChannel;
    else if ([string isEqualToString:@"Playlist"]) return kYTSearchResultTypePlaylist;
    else if ([string isEqualToString:@"Channel List"]) return kYTSearchResultTypeChannelList;
    else if ([string isEqualToString:@"Video"]) return kYTSearchResultTypeVideo;
     else if ([string isEqualToString:@"Unknown"]) return kYTSearchResultTypeUnknown;
     else return kYTSearchResultTypeUnknown;
}

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static KBYourTube *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            shared = [KBYourTube new];
            [shared startReachabilityMonitoring];
            shared.deviceController = [[APDeviceController alloc] init];
        });
    }
    
    return shared;
    
}

- (void)documentFromURL:(NSString *)theURL completion:(void(^)(ONOXMLDocument *document))block {

    //NSLog(@"dataString: %@", dataString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:theURL]];
    //request.HTTPBody = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"GET";
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    
    //NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@".youtube.com"]];
    
    //DLog(@"cookies: %@", cookies);
    
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    [request setAllHTTPHeaderFields:headers];
    /*
    //DLog(@"cookies: %@", cookies);
    if (cookies != nil){
        [request setHTTPShouldHandleCookies:YES];
        
        [self addCookies:cookies forRequest:request];
    }
    */
    // Look for an existing account with this email
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{@"Accept": @"application/json",
                                                   @"Accept-Language": @"en"};
    sessionConfiguration.HTTPShouldSetCookies = YES;
    sessionConfiguration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    
    
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
        
        
        
        if (data)
        {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            
            NSString *rawRequestResult = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            
           ONOXMLDocument *xmlDocument =  [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
            
            block(xmlDocument);
            
        } else {
            
            block(nil);
            
            DLog(@"no data!");
        }
    }];
    [postDataTask resume];
    
    
}

- (ONOXMLDocument *)documentFromURL:(NSString *)theURL {
    //<li><div class="display-message"
    NSString *rawRequestResult = [self stringFromRequest:theURL];
    return [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
}

- (BOOL)isSignedIn {
    return [[TYAuthUserManager sharedInstance] authorized];
}

- (NSString *)shelfFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"shelf.plist"];
}

#if TARGET_OS_TV
- (void)fetchUserDetailsWithCompletion:(void(^)(NSArray <KBSectionProtocol>*userDetails, NSString *username))completionBlock {
    __block NSMutableArray *finishedArray = [NSMutableArray new];
    //NSDictionary *userDetails = [self userDetails];
    @weakify(self);
    [self getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *userDetails) {
        self_weak_.userDetails = userDetails;
        NSString *channelID = userDetails[@"channelID"];
        DLog(@"channelID: %@", channelID);
        NSString *userName = userDetails[@"userName"];
        if ([[userDetails allKeys]containsObject:@"altUserName"]) {
            userName = userDetails[@"altUserName"];
        }
        NSArray <KBYTSearchResult *> *playlists = userDetails[@"results"];
        [playlists enumerateObjectsUsingBlock:^(KBYTSearchResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.resultType == kYTSearchResultTypePlaylist) {
                KBSection *playlistSection = [obj sectionRepresentation];
                [finishedArray addObject:playlistSection];
            }
        }];
        
        NSArray <KBCollectionItemProtocol> *channels = userDetails[@"channels"];
        if (channels.count > 0){
            KBSection *channelsSection = [KBSection new];
            channelsSection.title = @"Channels";
            channelsSection.size = @"320x240";
            channelsSection.type = @"standard";
            channelsSection.autoScroll = false;
            channelsSection.infinite = false;
            channelsSection.uniqueId = KBYTUserChannelsID;
            channelsSection.className = @"KBSection";
            channelsSection.sectionResultType = kYTSearchResultTypeChannelList; //there it is!
            channelsSection.content = channels;
            [finishedArray addObject:channelsSection];
        }
        
        NSArray <KBCollectionItemProtocol> *channelHistoryItems = [[TYTVHistoryManager sharedInstance] channelHistoryObjects];
        if (channelHistoryItems.count > 0) {
            KBSection *channelHistory = [KBSection new];
            channelHistory.title = @"Channel History";
            channelHistory.size = @"320x240";
            channelHistory.type = @"standard";
            channelHistory.autoScroll = false;
            channelHistory.infinite = false;
            channelHistory.uniqueId = KBYTUserChannelHistoryID;
            channelHistory.sectionResultType = kYTSearchResultTypeChannelList; //there it is!
            channelHistory.content = channelHistoryItems;
            channelHistory.className = @"KBSection";
            [finishedArray addObject:channelHistory];
        }
        
        NSArray <KBCollectionItemProtocol> *videoHistoryItems = [[TYTVHistoryManager sharedInstance] videoHistoryObjects];
        if (videoHistoryItems.count > 0) {
            KBSection *videoHistory = [KBSection new];
            videoHistory.title = @"Video History";
            videoHistory.size = @"320x240";
            videoHistory.type = @"standard";
            videoHistory.autoScroll = false;
            videoHistory.infinite = false;
            videoHistory.uniqueId = KBYTUserVideoHistoryID;
            videoHistory.sectionResultType = kYTSearchResultTypeChannelList; //there it is!
            videoHistory.content = videoHistoryItems;
            videoHistory.className = @"KBSection";
            [finishedArray addObject:videoHistory];
        }
        
        [[KBYourTube sharedInstance] getChannelVideos:channelID completionBlock:^(KBYTChannel *channel) {
            KBSection *section = [KBSection new];
            section.title = userName;
            section.size = @"640x480";
            section.type = @"banner";
            section.autoScroll = false;
            section.infinite = false;
            section.uniqueId = channelID;
            section.className = @"KBSection";
            section.sectionResultType = kYTSearchResultTypeChannel;
            //DLog(@"videos: %@", channel.videos);
            section.content = channel.videos;
            section.channel = channel;
            [finishedArray insertObject:section atIndex:0];
            completionBlock(finishedArray, userName);
        } failureBlock:^(NSString *error) {
            DLog(@"error getting your channel videos: %@", error);
            completionBlock(finishedArray, userName);
        }];
    } failureBlock:^(NSString *error) {
        
    }];
    
    
}
#endif

- (void)getUserDetailsDictionaryWithCompletionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                                       failureBlock:(void(^)(NSString *error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            BOOL signedIn = [self isSignedIn];
            NSString *errorString = @"Unknown error occurred";
            __block NSMutableDictionary *returnDict = [NSMutableDictionary new];
            __block NSMutableArray *itemArray = [NSMutableArray new];
            if (signedIn == true) {
                
//#ifndef SHELF_EXT
                TYAuthUserManager *authManager = [TYAuthUserManager sharedInstance];
                [authManager getPlaylistsWithCompletion:^(NSArray<KBYTSearchResult *> *playlists, NSString *error) {
                    TLog(@"got playlists");
                    if (playlists.count > 0) {
                        [itemArray addObjectsFromArray:playlists];
                        if (![[returnDict allKeys] containsObject:@"channelID"]){
                            returnDict[@"channelID"] = [playlists firstObject].channelId;
                        }
                        returnDict[@"userName"] = [playlists firstObject].author;
                        
                    }
                    [authManager getChannelListWithCompletion:^(NSArray<KBYTSearchResult *> *channels, NSString *error) {
                        TLog(@"got channels");
                        if (channels.count > 0) {
                            returnDict[@"channels"] = channels;
                            if (![[returnDict allKeys] containsObject:@"channelID"]){
                                returnDict[@"channelID"] = [channels firstObject].channelId;
                            }
                        }
                        [authManager getProfileDetailsWithCompletion:^(NSDictionary *profileDetails, NSString *error) {
                            if (error) {
                                TLog(@"error occured: %@", error);
                            } else {
                                NSString *userName = profileDetails[@"title"];
                                NSString *channelID = profileDetails[@"channelID"];
                                NSString *thumbURL = profileDetails[@"url"];
                                TLog(@"profileDetails: %@", profileDetails);
                                KBYTSearchResult *userChannel = [KBYTSearchResult new];
                                userChannel.title = @"Your channel";
                                userChannel.author = userName;
                                userChannel.videoId = channelID;
                                //userChannel.details = [NSString stringWithFormat:@"%lu videos", channelVideoCount];
                                userChannel.imagePath = thumbURL;
                                userChannel.resultType =kYTSearchResultTypeChannel;
                                //[itemArray addObject:userChannel];
                                returnDict[@"results"] = itemArray;
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (returnDict != nil) {
                                        [[returnDict convertObjectsToDictionaryRepresentations] writeToFile:[self shelfFile] atomically:true];
                                        completionBlock(returnDict);
                                    } else {
                                        failureBlock(errorString);
                                    }
                                });
                            }
                        }];
                    }];
                }];
                
                return;
                               
//#endif
                
            } else {
                errorString = @"Not signed in";
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (returnDict != nil)
                {
                    completionBlock(returnDict);
                } else {
                    failureBlock(errorString);
                }
                
                
            });
            
        }
        
    });
}

///aircontrol code, this is used to play media straight into firecore's youtube appliance on ATV 2

- (void)playMedia:(KBYTMedia *)media ToDeviceIP:(NSString *)deviceIP {
    NSLog(@"ac stream: %@ to deviceIP: %@", media, deviceIP);
    NSURL *deviceURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/playyt=%@", deviceIP, media.videoId]];
    
    // Create URL request and set url, method, content-length, content-type, and body
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:deviceURL];
    [request setHTTPMethod:@"GET"];
    NSURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    NSLog(@"aircontrol return details: %@", datString);
}

#if TARGET_OS_IOS
- (void)pauseAirplay {
    [[KBYTMessagingCenter sharedInstance] pauseAirplay];
}

- (void)stopAirplay {
    [[KBYTMessagingCenter sharedInstance] stopAirplay];
}

- (NSInteger)airplayStatus {
    return [[KBYTMessagingCenter sharedInstance] airplayStatus];
}

- (void)airplayStream:(NSString *)stream ToDeviceIP:(NSString *)deviceIP {
    [[KBYTMessagingCenter sharedInstance] airplayStream:stream ToDeviceIP:deviceIP];
    
}

#endif

- (NSDictionary *)returnFromURLRequest:(NSString *)requestString requestType:(NSString *)type {
    NSURL *deviceURL = [NSURL URLWithString:requestString];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:deviceURL];
    [request setHTTPMethod:type];
    [request addValue:@"MediaControl/1.0" forHTTPHeaderField:@"User-Agent"];
    NSURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    NSLog(@"return details: %@", datString);
    return [datString dictionaryValue];
}

- (NSString *)stringFromPostRequest:(NSString *)url withParams:(NSDictionary *)params {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:10];
#ifndef SHELF_EXT
    /*
    AFOAuthCredential *cred = [AFOAuthCredential retrieveCredentialWithIdentifier:@"default"];
    if (cred) {
        NSString *authorization = [NSString stringWithFormat:@"Bearer %@",cred.accessToken];
        [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    }
     */
#endif
    NSURLResponse *response = nil;
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSData *json = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingFragmentsAllowed error:nil];
    [request setHTTPBody:json];
    //[request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B410 Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
}

- (NSInteger)resultNumber:(NSString *)html {
    NSScanner *theScanner;
    NSString *text = nil;
    
    theScanner = [NSScanner scannerWithString:html];
    while ([theScanner isAtEnd] == NO) {
        
        // find start of tag
        [theScanner scanUpToString:@"first-focus\">About " intoString:NULL] ;
        
        // find end of tag
        [theScanner scanUpToString:@"results" intoString:&text] ;
    }
    
    return [[[[[text componentsSeparatedByString:@"About"] lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""] integerValue];
}

- (NSArray *)ytSearchBasics:(NSString *)html {
    
    NSScanner *theScanner;
    NSString *text = nil;
    
    theScanner = [NSScanner scannerWithString:html];
    NSMutableArray *theArray = [NSMutableArray new];
    while ([theScanner isAtEnd] == NO) {
        
        // find start of tag
        [theScanner scanUpToString:@"/watch?v=" intoString:NULL] ;
        
        // find end of tag
        [theScanner scanUpToString:@"\"" intoString:&text] ;
        
        NSString *newString = [[text componentsSeparatedByString:@"="] lastObject];
        
        if (![theArray containsObject:newString])
        {
            [theArray addObject:newString];
        }
        // replace the found tag with a space
        //(you can filter multi-spaces out later if you wish)
        //html = [html stringByReplacingOccurrencesOfString:[ NSString stringWithFormat:@"%@>", text] withString:@" "];
        
    } // while //
    
    return theArray;
    
}

- (NSString *)videoInfoPage:(NSString *)html {
    
    NSScanner *theScanner;
    NSString *text = nil;
    
    theScanner = [NSScanner scannerWithString:html];
    while ([theScanner isAtEnd] == NO) {
        
        //[theScanner scanUpToString:@"<link itemprop=\"url\"" intoString:NULL];
        
        //[theScanner scanUpToString:@"<div id=\"watch7-speedyg-area\">" intoString:&text];
        
        [theScanner scanUpToString:@"<meta name=\"title\"" intoString:NULL] ;
        
        [theScanner scanUpToString:@"<link rel=\"alternate\"" intoString:&text] ;
        
        
    } // while //
    
    return [NSString stringWithFormat:@"<div>%@</div>", text];
    
}


- (NSString *)videoDescription:(NSString *)videoID {
    NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", videoID];
    NSString *request = [self stringFromRequest:requestString];
    NSString *trimmed = [self videoInfoPage:request];
    APDocument *rawDoc = [[APDocument alloc] initWithString:trimmed];
    APElement *descElement = [[rawDoc rootElement] elementContainingNameString:@"description"];
    return [descElement valueForAttributeNamed:@"content"];
}

- (void)getVideoDescription:(NSString *)videoID
            completionBlock:(void(^)(NSString* description))completionBlock
               failureBlock:(void(^)(NSString* error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            
            NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", videoID];
            NSString *request = [self stringFromRequest:requestString];
            NSString *trimmed = [self videoInfoPage:request];
            APDocument *rawDoc = [[APDocument alloc] initWithString:trimmed];
            APElement *descElement = [[rawDoc rootElement] elementContainingNameString:@"description"];
            NSString *desc = [descElement valueForAttributeNamed:@"content"];
            //doneski!
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([desc length] > 0)
                {
                    completionBlock(desc);
                } else {
                    failureBlock(@"fail");
                }
            });
        }
    });
    
}


- (void)getPlaylistVideos:(NSString *)listID
             continuation:(NSString *)continuationToken
          completionBlock:(void(^)(KBYTPlaylist *playlist))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSString *errorString = nil;
            NSString *url = [self nextURL];
            //NSLog(@"url: %@", url);
            //DLog(@"url: %@ videoID: %@", url, result.videoId);
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForPlaylist:listID continuation:continuationToken];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            //NSLog(@"body: %@ for: %@ %@", jsonDict, url, params);
            //        DLog(@"array: %lu", vrArray.count);
            //[jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"drake.plist"] atomically:true];
            __block NSMutableArray *videos = [NSMutableArray new];
            KBYTPlaylist *playlist = [KBYTPlaylist new];
            id cc = [jsonDict recursiveObjectForKey:@"continuationCommand"];
            playlist.playlistID = listID;
            //TLog(@"cc: %@", cc);
            playlist.continuationToken = cc[@"token"];
            NSDictionary *plRoot = [jsonDict recursiveObjectForKey:@"playlist"][@"playlist"];
            __block NSMutableArray* videoIds = [NSMutableArray new];
            if (plRoot) {
                NSString *owner = [plRoot recursiveObjectForKey:@"ownerName"][@"simpleText"];
                NSString *title = plRoot[@"title"];
                //NSLog(@"owner: %@ title: %@", owner, title);
                playlist.owner = owner;
                playlist.title = title;
                NSArray *vr = [jsonDict recursiveObjectsForKey:@"playlistPanelVideoRenderer"];
                //NSLog(@"vr: %@", vr);
                //[plRoot writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"root.plist"] atomically:true];
                [vr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    //NSLog(@"%@", obj[@"playlistPanelVideoRenderer"]);
                    NSDictionary *current = obj[@"playlistPanelVideoRenderer"];
                    if (current) {
                        
                        KBYTSearchResult *searchItem = [self searchResultFromVideoRenderer:current];
                        [videoIds addObject:searchItem.videoId];
                        [videos addObject:searchItem];
                    } else {
                        NSString *message = [obj recursiveObjectForKey:@"simpleText"];
                        if (message){
                            //TLog(@"no vr: %@", obj);
                            //TLog(@"do we have a message?: %@", message);
                        } else {
                            TLog(@"no vr: %@", obj);
                        }
                    }
                }];
                //playlist.videos = videos;
            } else {
                NSArray *continuationItems = [jsonDict recursiveObjectForKey:@"continuationItems"];
                if (continuationItems) {
                    //TLog(@"we found continuation items: %lu", continuationItems.count);
                    [continuationItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        //NSLog(@"%@", obj[@"playlistPanelVideoRenderer"]);
                        NSDictionary *current = [obj recursiveObjectLikeKey:@"videoRenderer"];
                        if (current) {
                            
                            KBYTSearchResult *searchItem = [self searchResultFromVideoRenderer:current];
                            [videoIds addObject:searchItem.videoId];
                            [videos addObject:searchItem];
                        } else {
                            //TLog(@"no vr: %@", obj);
                            NSString *message = [obj recursiveObjectForKey:@"simpleText"];
                            if (message){
                                //TLog(@"do we have a message?: %@", message);
                            } else {
                                TLog(@"no vr: %@", obj);
                            }
                        }
                    }];
                    //playlist.videos = videos;
                }
            }
            //NSLog(@"playlist video count: %lu", videos.count);
            /*
            NSMutableArray *vrArray = [NSMutableArray new];
            [jsonDict recursiveInspectObjectLikeKey:@"videoRenderer" saving:vrArray];
            //NSLog(@"vrArray: %@", new);
            
            if ([vrArray count] > 0){
                [vrArray enumerateObjectsUsingBlock:^(id  _Nonnull video, NSUInteger idx, BOOL * _Nonnull stop) {
                    KBYTSearchResult *result = [self searchResultFromVideoRenderer:video];
                    //DLog(@"shelf item %lu subindex %lu is a video object", idx, idx2);
                    [videos addObject:result];
                    //DLog(@"result: %@", result);
                    
                }];
            }*/
            playlist.videos = videos;
            
            //NSLog(@"videos: %@", videos);
            //NSLog(@"root info: %@", rootInfo);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(jsonDict != nil) {
                    if (completionBlock){
                        completionBlock(playlist);
                    }
                } else {
                    if (failureBlock){
                    failureBlock(errorString);
                    }
                }
            });
        }
    });
    
}
- (void)getPlaylistVideos:(NSString *)listID
          completionBlock:(void(^)(KBYTPlaylist *playlist))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock {
    [self getPlaylistVideos:listID continuation:nil completionBlock:completionBlock failureBlock:failureBlock];
}

- (KBYTSearchResult *)searchResultFromVideoRenderer:(NSDictionary *)current {
    NSString *lengthText = current[@"lengthText"][@"simpleText"];
    if (!lengthText){
        lengthText = [[current recursiveObjectForKey:@"thumbnailOverlayTimeStatusRenderer"] recursiveObjectForKey:@"simpleText"];
        if ([lengthText isEqualToString:@"UPCOMING"]){
            //DLog(@"%@", current);
        }
    }
    NSDictionary *title = [current recursiveObjectForKey:@"title"];
    NSString *fullTitle = [title recursiveObjectForKey:@"text"];
    if (!fullTitle) {
        fullTitle = [title recursiveObjectForKey:@"simpleText"];
        if (fullTitle.length == 0) {
            //TLog(@"current: %@", current);
        }
    }
    NSString *vid = [current recursiveObjectForKey:@"videoId"];//current[@"videoId"];
    NSString *viewCountText = current[@"viewCountText"][@"simpleText"];
    NSArray *thumbnails = current[@"thumbnail"][@"thumbnails"] ? current[@"thumbnail"][@"thumbnails"] : [current recursiveObjectForKey:@"thumbnail"][@"thumbnails"];
    //https://i.ytimg.com/vi/VIDEO_ID/hqdefault.jpg
    NSDictionary *thumb = thumbnails.lastObject;
    NSString *imagePath = thumb[@"url"];
    //NSInteger width = [thumb[@"width"] integerValue];
    if (!imagePath){
        imagePath = [NSString stringWithFormat:@"https://i.ytimg.com/vi/%@/maxresdefault.jpg", vid];
    } else {
        imagePath = imagePath; //convert to hi-res later
    }
    NSDictionary *longBylineText = [current recursiveObjectForKey:@"longBylineText"];
    if (!longBylineText) {
        longBylineText = [current recursiveObjectForKey:@"shortBylineText"];
    }
    NSDictionary *ownerText = current[@"ownerText"];
    if (!ownerText) {
        ownerText = longBylineText;
    }
    NSString *channelId = [current recursiveObjectForKey:@"browseId"];
    NSString *playlistId = [[current recursiveObjectForKey:@"watchEndpoint"] recursiveObjectForKey:@"playlistId"];
    //current[@"publishedTimeText"][@"simpleText"];
    KBYTSearchResult *searchItem = [KBYTSearchResult new];
    searchItem.details = [longBylineText recursiveObjectForKey:@"text"];
    searchItem.author = [ownerText recursiveObjectForKey:@"text"];
    searchItem.title = fullTitle;
    searchItem.duration = lengthText;
    searchItem.videoId = vid;
    searchItem.views = viewCountText;
    searchItem.age = current[@"publishedTimeText"][@"simpleText"];
    searchItem.originalImagePath = imagePath;
    searchItem.imagePath = [imagePath maxResVideoURL];
    searchItem.channelId = channelId;
    searchItem.playlistId = playlistId;
    searchItem.resultType = kYTSearchResultTypeVideo;
    return searchItem;
}


- (void)getChannelVideosAlt:(NSString *)channelID
          completionBlock:(void(^)(KBYTChannel *channel))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock {
    [self getChannelVideosAlt:channelID continuation:nil completionBlock:completionBlock failureBlock:failureBlock];
}

- (void)getChannelVideosAlt:(NSString *)channelID
               continuation:(NSString *)continuationToken
          completionBlock:(void(^)(KBYTChannel *channel))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //UCO9zJy7HWrIS3ojB4Lr7Yqw
        @autoreleasepool {
            NSString *url = [self browseURL];
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForChannelID:channelID continuation:continuationToken];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            //TLog(@"params: %@", params);
            NSLog(@"getting details for channelId: %@", channelID);
            
            //NSLog(@"channelID: %@ body: %@ for: %@ %@",channelID, jsonDict, url, params);
            //NSMutableArray* arr = [NSMutableArray array];
            //[self obtainKeyPaths:jsonDict intoArray:arr withString:nil];
            NSString *fileName = [channelID stringByAppendingPathExtension:@"plist"];
            DLog(@"file: %@", [NSHomeDirectory() stringByAppendingPathComponent:fileName]);
            
            [jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:fileName] atomically:true];
            
            NSArray *banner = [jsonDict recursiveObjectForKey:@"imageBannerViewModel"][@"image"][@"sources"];
            NSString *lastBanner = [banner lastObject][@"url"];
            //NSLog(@"our banners: %@", lastBanner);
            id cc = [jsonDict recursiveObjectForKey:@"continuationCommand"];
            //recursiveObjectsFor(@"continuationCommand", jsonDict, ccs);
            //DLog(@"ccs: %@", ccs);
            NSDictionary *details = [jsonDict recursiveObjectForKey:@"topicChannelDetailsRenderer"];
            if (!details) {
                details = [jsonDict recursiveObjectForKey:@"channelMetadataRenderer"];
                //DLog(@"details: %@", details);
            }
            NSDictionary *subscriberCount = [jsonDict recursiveObjectForKey:@"subscriberCountText"];
            //NSLog(@"subscriber count: %@", subscriberCount);
            NSDictionary *title = [details recursiveObjectForKey:@"title"];
            NSDictionary *subtitle = [details recursiveObjectForKey:@"subtitle"];
            NSArray *thumbnails = [details recursiveObjectForKey:@"thumbnails"];
            NSDictionary *thumb = [thumbnails lastObject];
            //NSInteger width = [thumb[@"height"] integerValue];
            NSString *imagePath = [thumb[@"url"] highResChannelURL];
            __block KBYTChannel *channel = [KBYTChannel new];
            if ([title isKindOfClass:[NSDictionary class]]){
                channel.title = title[@"simpleText"];
            } else {
                channel.title = (NSString *)title;
            }
            if (!subtitle){
                channel.subtitle = details[@"description"];
            } else {
                channel.subtitle = subtitle[@"simpleText"];
            }
            channel.channelID = channelID;
            if ([subscriberCount respondsToSelector:@selector(isEqualToString:)]){
                channel.subscribers = (NSString*)subscriberCount;
            } else {
                channel.subscribers = subscriberCount[@"simpleText"];
            }
            channel.image = imagePath;
            channel.url = [details recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"canonicalBaseUrl"];
            channel.continuationToken = cc[@"token"];
            //if (ccs.count > 1) {
              //  channel.continuationTokens = ccs;
            //}
            channel.banner = lastBanner;
            //DLog(@"details: %@", details);
            //title,subtitle,thumbnails
            //[jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"music.plist"] atomically:true];
            recursiveObjectsLike(@"itemSectionRenderer", jsonDict, sect);
            //NSArray *sect = [jsonDict recursiveObjectsLikeKey:@"itemSectionRenderer"];
            if (sect.count == 0) {
                NSDictionary *richGridRenderer = [jsonDict recursiveObjectLikeKey:@"richGridRenderer"];
                sect = richGridRenderer[@"contents"];
                //TLog(@"no content for some retarded reason");
            }
            __block NSMutableArray *sections = [NSMutableArray new];
            __block KBYTSection *backup = nil;
            [sect enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *shelf = [obj recursiveObjectLikeKey:@"shelfRenderer"];
                if (!shelf) {
                    NSDictionary *video = [obj recursiveObjectLikeKey:@"videoRenderer"];
                    if (!backup){
                        backup = [KBYTSection new];
                    }
                    KBYTSearchResult *res = [self searchResultFromVideoRenderer:video];
                    if (res.videoId) {
                        [backup addResult:res];
                    } else {
                        //TLog(@"no videoRenderer!: %@", obj);
                        id cc = [obj recursiveObjectForKey:@"continuationCommand"];
                        //TLog(@"cc: %@", cc);
                        channel.continuationToken = cc[@"token"];
                        NSDictionary *channelRender = [obj recursiveObjectForKey:@"channelVideoPlayerRenderer"];
                        if (channelRender){
                            //TLog(@"channel renderer found: %@", [channelRender allKeys]);
                            KBYTSearchResult *res = [self searchResultFromVideoRenderer:channelRender];
                            if (res.videoId) {
                                //TLog(@"found video: %@", res);
                                res.channelId = channel.channelID;
                                [backup addResult:res];
                            }
                        }
                        
                    }
                    //TLog(@"idx: %lu of %lu", idx, [sect count]);
                    if (idx+1 == sect.count && backup){
                        TLog(@"adding straggler: %@", backup);
                        [sections addObject:backup];
                        backup = nil;
                    }
                } else { //no shelf
                    if (backup) {
                        //DLog(@"backup: %@", backup);
                        if (backup.content.count > 0) {
                            [sections addObject:backup];
                        }
                        backup = nil;
                    }
                    //NSDictionary *rend = [renderers firstObject];
                    NSDictionary *title = [shelf recursiveObjectForKey:@"title"];
                    KBYTSection *section = [KBYTSection new];
                    section.title = title[@"simpleText"] ? title[@"simpleText"] : [title recursiveObjectForKey:@"text"];
                    //NSLog(@"idx %lu shelf: %@", idx, section.title);
                    
                    NSArray *videos = [shelf recursiveObjectsLikeKey:@"videoRenderer"];
                    //NSLog(@"videos: %@", videos);
                    __block NSMutableArray *content = [NSMutableArray new];
                    if (videos){
                        //NSLog(@"videos: %lu", videos.count);
                        [videos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSString *first = [[obj allKeys] firstObject];
                            NSDictionary *vid = obj[first];
                            if (vid){
                                KBYTSearchResult *video = [self searchResultFromVideoRenderer:vid];
                                video.channelId = channel.channelID;
                                //NSLog(@"video: %@", video);
                                [content addObject:video];
                            }
                        }];
                    } else {
                        NSArray *stations = [shelf recursiveObjectsLikeKey:@"stationRenderer"];
                        if (stations.count > 0){
                            //NSLog(@"stations: %lu", stations.count);
                            [stations enumerateObjectsUsingBlock:^(id  _Nonnull station, NSUInteger idx, BOOL * _Nonnull stop) {
                                NSString *firstKey = [[station allKeys] firstObject];
                                NSDictionary *playlist = station[firstKey];
                                NSDictionary *title = [playlist recursiveObjectForKey:@"title"];
                                NSString *cis = [playlist recursiveObjectForKey:@"playlistId"];
                                NSArray *thumbnails = [playlist recursiveObjectForKey:@"thumbnail"][@"thumbnails"];
                                NSString *last = thumbnails.lastObject[@"url"];
                                NSDictionary *desc = [playlist recursiveObjectForKey:@"description"];
                                KBYTSearchResult *searchItem = [KBYTSearchResult new];
                                searchItem.title = title[@"simpleText"] ? title[@"simpleText"] : [title recursiveObjectForKey:@"text"];;
                                searchItem.duration = [playlist[@"videoCountText"] recursiveObjectForKey:@"text"];
                                searchItem.videoId = cis;
                                searchItem.channelId = channel.channelID;
                                searchItem.imagePath = last;
                                searchItem.author = channel.title;
                                searchItem.resultType = kYTSearchResultTypePlaylist;
                                searchItem.details = [desc recursiveObjectForKey:@"simpleText"];
                                //NSLog(@"searchItem: %@", searchItem);
                                [content addObject:searchItem];
                            }];
                        } else {
                            
                            NSArray *playlistRenders = [shelf recursiveObjectsLikeKey:@"playlistRenderer"];
                            if (playlistRenders.count > 0){
                                
                                //NSLog(@"playlists count: %lu", stations.count);
                                [playlistRenders enumerateObjectsUsingBlock:^(id  _Nonnull station, NSUInteger idx, BOOL * _Nonnull stop) {
                                    NSString *firstKey = [[station allKeys] firstObject];
                                    NSDictionary *playlist = station[firstKey];
                                    NSDictionary *title = [playlist recursiveObjectForKey:@"title"];
                                    NSString *cis = [playlist recursiveObjectForKey:@"playlistId"];
                                    NSArray *thumbnails = [playlist recursiveObjectForKey:@"thumbnail"][@"thumbnails"];
                                    NSString *last = thumbnails.lastObject[@"url"];
                                    NSDictionary *desc = [playlist recursiveObjectForKey:@"description"];
                                    KBYTSearchResult *searchItem = [KBYTSearchResult new];
                                    searchItem.title = title[@"simpleText"] ? title[@"simpleText"] : [title recursiveObjectForKey:@"text"];
                                    searchItem.duration = playlist[@"videoCountShortText"][@"simpleText"];
                                    searchItem.videoId = cis;
                                    searchItem.imagePath = last;
                                    searchItem.channelId = channel.channelID;
                                    searchItem.age = playlist[@"publishedTimeText"][@"simpleText"];
                                    searchItem.author = channel.title;
                                    searchItem.resultType = kYTSearchResultTypePlaylist;
                                    searchItem.details = [desc recursiveObjectForKey:@"simpleText"];
                                    [content addObject:searchItem];
                                }];
                                
                            } else {
                                playlistRenders = [shelf recursiveObjectsLikeKey:@"channelRenderer"];
                                if (playlistRenders.count > 0){
                                    //NSLog(@"channels count: %lu", stations.count);
                                    [playlistRenders enumerateObjectsUsingBlock:^(id  _Nonnull channelObj, NSUInteger idx, BOOL * _Nonnull stop) {
                                        NSString *firstKey = [[channelObj allKeys] firstObject];
                                        NSDictionary *channel = channelObj[firstKey];
                                        
                                        NSDictionary *title = channel[@"title"];//[channel recursiveObjectForKey:@"title"];
                                        NSString *cis = channel[@"channelId"];
                                        NSArray *thumbnails = channel[@"thumbnail"][@"thumbnails"];
                                        NSDictionary *longBylineText = channel[@"longBylineText"];
                                        NSDictionary *thumb = thumbnails.lastObject;
                                        NSString *imagePath = thumb[@"url"];
                                        NSString *originalImagePath = imagePath;
                                        NSInteger width = [thumb[@"height"] integerValue];
                                        if (width < 400){
                                            //TLog(@"generate thumb manually: %lu", width);
                                            
                                            imagePath = [self hiRestChannelImageFromDict:thumb];
                                        }
                                        if (![imagePath containsString:@"https:"]){
                                            imagePath = [NSString stringWithFormat:@"https:%@", imagePath];
                                        }
                                        KBYTSearchResult *searchItem = [KBYTSearchResult new];
                                        searchItem.author = [longBylineText recursiveObjectForKey:@"text"];
                                        searchItem.title = title[@"simpleText"];
                                        searchItem.author = title[@"simpleText"];
                                        searchItem.duration = [channel[@"videoCountText"] recursiveObjectForKey:@"text"];
                                        searchItem.videoId = cis;
                                        searchItem.channelId = channelID;
                                        searchItem.imagePath = imagePath;
                                        searchItem.originalImagePath = originalImagePath;
                                        searchItem.resultType = kYTSearchResultTypeChannel;
                                        searchItem.details = [channel recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"canonicalBaseUrl"];
                                        NSArray *itemDesc = [channel recursiveObjectForKey:@"videoCountText"][@"runs"];
                                        if (itemDesc){
                                            searchItem.itemDescription = [itemDesc runsToString];
                                        } else {
                                            //try subscriberCountText
                                            searchItem.itemDescription = channel[@"subscriberCountText"][@"simpleText"];
                                            //TLog(@"desc: %@", searchItem.itemDescription);
                                        }
                                        //NSLog(@"channel: %@ keys: %@", searchItem, channel.allKeys);
                                        [content addObject:searchItem];
                                    }];
                                    
                                } else { //shorts maybe?
                                    //NSLog(@"rend: %@", rend);
                                    recursiveObjectsLike(@"shortsLockupViewModel", shelf, stations);
                                    //NSLog(@"reels: %lu", stations.count);
                                    if (stations.count == 0){
                                        //NSLog(@"rend: %@", shelf);
                                    }
                                    [stations enumerateObjectsUsingBlock:^(id  _Nonnull reel, NSUInteger idx, BOOL * _Nonnull stop) {
                                        //NSString *firstKey = [[reel allKeys] firstObject];
                                        NSDictionary *reelObject = reel; //for now //reel[firstKey];
                                        NSArray *thumbnails = [reelObject recursiveObjectForKey:@"thumbnail"][@"sources"];
                                        NSString *last = thumbnails.lastObject[@"url"];
                                        NSDictionary *overlay = reelObject[@"overlayMetadata"];
                                        //DLog(@"overlay meta: %@", overlay);
                                        //DLog(@"keys: %@", [reelObject allKeys]);
                                        KBYTSearchResult *searchItem = [KBYTSearchResult new];
                                        searchItem.title = overlay[@"primaryText"][@"content"];
                                        searchItem.videoId = [reelObject recursiveObjectForKey:@"videoId"];//reelObject[@"videoId"];
                                        searchItem.views = overlay[@"secondaryText"][@"content"];
                                        searchItem.resultType = kYTSearchResultTypeVideo;
                                        searchItem.imagePath = last;
                                        searchItem.channelId = channelID;
                                        searchItem.age = [reelObject recursiveObjectForKey:@"timestampText"][@"simpleText"];
                                        searchItem.author = channel.title;
                                        searchItem.duration = @"Short";
                                        //NSLog(@"searchItem: %@", searchItem);
                                        [content addObject:searchItem];
                                    }];
                                }
                                
                            }
                            
                        }
                        
                    }
                    section.content = content;
                    if (content.count > 0) {
                        [sections addObject:section];
                    } else {
                        DLog(@"section is empty, skipping: %@", section);
                    }
                }
                
                
            }];
            //NSLog(@"sections: %@", sections);
            //NSLog(@"section count: %lu", sections.count);
            //NSLog(@"one: %@", [sections firstObject]);
            channel.sections = sections;
            /*
             __block NSMutableArray *items = [NSMutableArray new];
             __block NSMutableArray *playlists = [NSMutableArray new];
             
            NSMutableArray *vrArray = [NSMutableArray new];
            [jsonDict recursiveInspectObjectLikeKey:@"videoRenderer" saving:vrArray];
            NSMutableArray *plArray = [NSMutableArray new];
            [jsonDict recursiveInspectObjectLikeKey:@"stationRenderer" saving:plArray];
            if ([vrArray count] > 0){
                [vrArray enumerateObjectsUsingBlock:^(id  _Nonnull video, NSUInteger idx, BOOL * _Nonnull stop) {
                    KBYTSearchResult *result = [self searchResultFromVideoRenderer:video];
                    //DLog(@"shelf item %lu subindex %lu is a video object", idx, idx2);
                    [items addObject:result];
                    //DLog(@"result: %@", result);
                    
                }];
            }
            
            if ([plArray count] > 0){
                [plArray enumerateObjectsUsingBlock:^(id  _Nonnull playlist, NSUInteger idx, BOOL * _Nonnull stop) {
                    //NSLog(@"playlist: %@", playlist);
                    NSDictionary *title = [playlist recursiveObjectForKey:@"title"];
                    NSString *cis = [playlist recursiveObjectForKey:@"playlistId"];
                    NSArray *thumbnails = playlist[@"thumbnail"][@"thumbnails"];
                    NSDictionary *desc = playlist[@"description"];
                    KBYTSearchResult *searchItem = [KBYTSearchResult new];
                    searchItem.title = title[@"simpleText"];
                    searchItem.duration = [playlist[@"videoCountText"] recursiveObjectForKey:@"text"];
                    searchItem.videoId = cis;
                    searchItem.imagePath = thumbnails.lastObject[@"url"];
                    searchItem.resultType = kYTSearchResultTypePlaylist;
                    searchItem.details = [desc recursiveObjectForKey:@"simpleText"];
                    [playlists addObject:searchItem];
                    //DLog(@"result: %@", searchItem);
                    
                }];
            }
            channel.channelID = channelID;
            channel.videos = items;
            channel.playlists = playlists;
            */
            //get the post body from the url above, gets the initial raw info we work with
            
            if (channel.allSectionItems.count == 0) {
                TLog(@"no items found!");
                if (channel.continuationTokens.count > 0) {
                    NSDictionary *token = [[[channel continuationTokens] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"token == %@", continuationToken]] firstObject];
                    if (token) {
                        DLog(@"found token: %@", token);
                        NSInteger index = [channel.continuationTokens indexOfObject:token];
                        DLog(@"found at index: %lu", index);
                        NSInteger next = index++;
                        if (next > channel.continuationTokens.count) {
                            DLog(@"do nothing, over count!");
                        } else {
                            NSString *token = [channel continuationTokens][next][@"token"];
                            DLog(@"trying new token: %@", token);
                            [self getChannelVideosAlt:channelID continuation:token completionBlock:^(KBYTChannel *channel) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (completionBlock) {
                                        completionBlock(channel);
                                    }
                                });
                            } failureBlock:^(NSString *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (completionBlock) {
                                        completionBlock(nil);
                                    }
                                });
                            }];
                            return;
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(channel);
                }
            });
            
        }
    });
    
}

- (void)getChannelVideos:(NSString *)channelID
            continuation:(NSString *)continuationToken
         completionBlock:(void (^)(KBYTChannel *))completionBlock
            failureBlock:(void (^)(NSString *))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSString *newChannelID = [NSString stringWithFormat:@"UU%@", [channelID substringFromIndex:2]];
            NSLog(@"oldChannelID: %@ new: %@", channelID, newChannelID);
            NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/channel/%@/videos", channelID];
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
            ONOXMLElement *root = [xmlDoc rootElement];
            // NSLog(@"root element: %@", root);//"meta[property=\"og:url\"]"
            ONOXMLElement *url = [root firstChildWithXPath:@"//meta[contains(@property, 'og:url')]"];
            ONOXMLElement *title = [root firstChildWithXPath:@"//meta[contains(@property, 'og:title')]"];
            ONOXMLElement *image = [root firstChildWithXPath:@"//meta[contains(@property, 'og:image')]"];
            NSString *finalURL = [url valueForAttribute:@"content"];
            NSString *finalTitle = [title valueForAttribute:@"content"];
            NSString *finalImage = [image valueForAttribute:@"content"];
            NSLog(@"url: %@ title: %@ image: %@", finalURL, finalTitle, finalImage);
            KBYTChannel *channel = [KBYTChannel new];
            channel.title = finalTitle;
            channel.url = finalURL;
            channel.image = finalImage;
            channel.channelID = channelID;
            /*
            id ogEnum = [root XPath:@"//meta[contains(@property, 'og:')]"];
            ONOXMLElement *currentElement = nil;
            while (currentElement = [ogEnum nextObject]) {
                NSLog(@"og: %@", currentElement);
            }*/
            
            //get the post body from the url above, gets the initial raw info we work with
            [self getPlaylistVideos:newChannelID continuation:continuationToken completionBlock:^(KBYTPlaylist *playlist) {
                //TLog(@"got playlist: %@", playlist);
                channel.videos = playlist.videos;
                channel.continuationToken = playlist.continuationToken;
                completionBlock(channel);
            } failureBlock:^(NSString *error) {
                failureBlock(nil);
            }];
        }
    });
    
}

- (void)getChannelVideos:(NSString *)channelID
          completionBlock:(void(^)(KBYTChannel *channel))completionBlock
            failureBlock:(void(^)(NSString *error))failureBlock {
    [self getChannelVideos:channelID continuation:nil completionBlock:completionBlock failureBlock:failureBlock];
}

- (NSString *)hiRestChannelImageFromDict:(NSDictionary *)dict {
    NSInteger height = [dict[@"height"] integerValue];
    NSString *findString = [NSString stringWithFormat:@"=s%lu", height];
    NSString *replaceString = @"=s480";
    NSString *origURL = dict[@"url"];
    return [origURL stringByReplacingOccurrencesOfString:findString withString:replaceString];
}

- (NSString *)attemptConvertImagePathToHiRes:(NSString *)imagePath {
    if ([imagePath rangeOfString:@"custom=true"].location == NSNotFound) {
        return imagePath;
    }
    NSURLComponents *comp = [[NSURLComponents alloc] initWithString:imagePath];
    
    NSMutableArray <NSURLQueryItem*> *newQuery = [[comp queryItems] mutableCopy];
    [[comp queryItems] enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *key = [obj name];
        if ([key isEqualToString:@"w"])
        {
            NSURLQueryItem *new = [NSURLQueryItem queryItemWithName:key value:@"640"];
            [newQuery replaceObjectAtIndex:idx withObject:new];
        } else if ([key isEqualToString:@"h"])
        {
            NSURLQueryItem *new = [NSURLQueryItem queryItemWithName:key value:@"480"];
            [newQuery replaceObjectAtIndex:idx withObject:new];
        }
        
    }];
    comp.queryItems = newQuery;
    return comp.URL.absoluteString;
}

- (void)getVideoDetailsForID:(NSString*)videoID
             completionBlock:(void(^)(KBYTMedia* videoDetails))completionBlock
                failureBlock:(void(^)(NSString* error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            KBYTMedia *rootInfo = nil;
            __block NSString *errorString = @"";
            NSString *url = [self playerURL];
            NSLog(@"url: %@", url);
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForVideo:videoID];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            DLog(@"body: %@ for: %@ %@", jsonDict, url, params);
            DLog(@"file: %@", [NSHomeDirectory() stringByAppendingPathComponent:@"file2.plist"]);
            [jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"file2.plist"] atomically:true];
            
            NSError *error = nil;
            rootInfo = [[KBYTMedia alloc] initWithJSON:jsonDict error:&error];
            //NSLog(@"root info: %@", rootInfo);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(rootInfo != nil)
                {
                    completionBlock(rootInfo);
                } else {
                    if (error) {
                        errorString = error.localizedDescription;
                    }
                    failureBlock(errorString);
                }
            });
        }
    });
    
}


- (void)apiSearch:(NSString *)search
             type:(KBYTSearchType)type
     continuation:(NSString *)continuation
  completionBlock:(void(^)(KBYTSearchResults *result))completionBlock
     failureBlock:(void(^)(NSString* error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSString *errorString = nil;
            NSString *url = [self searchURL];
            NSLog(@"url: %@", url);
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForSearch:search forType:type continuation:continuation];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            id jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            //NSLog(@"body: %@ for: %@ %@", jsonDict, url, params);
            KBYTSearchResults *results = [KBYTSearchResults new];
            [results processJSON:jsonDict filter:type];
            NSLog(@"video count: %lu", results.allItems.count);
            [jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"search.plist"] atomically:true];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(results != nil) {
                    completionBlock(results);
                } else {
                    failureBlock(errorString);
                }
            });
        }
    });
    //
}


#pragma mark video details

/*
 
 the only function you should ever have to call to get video streams
 take the video ID from a youtube link and feed it in to this function
 
 ie _7nYuyfkjCk from the link below include blocks for failure and success.
 
 
 https://www.youtube.com/watch?v=_7nYuyfkjCk
 
 
 */


- (void)getVideoDetailsForSearchResults:(NSArray*)searchResults
                        completionBlock:(void(^)(NSArray* videoArray))completionBlock
                           failureBlock:(void(^)(NSString* error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSMutableArray *finalArray = [NSMutableArray new];
            //NSMutableDictionary *rootInfo = [NSMutableDictionary new];
            __block NSString *errorString = @"";

            for (KBYTSearchResult *result in searchResults) {
                
                if (!result.videoId){
                    TLog(@"missing video id: %@ bail!", result);
                    continue;;
                }
                
                NSString *url = [self playerURL];
                DLog(@"url: %@ videoID: %@", url, result.videoId);
                //get the post body from the url above, gets the initial raw info we work with
                NSDictionary *params = [self paramsForVideo:result.videoId];
                NSString *body = [self stringFromPostRequest:url withParams:params];
                NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
                NSError *error = nil;
                //NSLog(@"body: %@ for: %@ %@", jsonDict, url, params);
                KBYTMedia *currentMedia = [[KBYTMedia alloc] initWithJSON:jsonDict error:&error];
                if(currentMedia) {
                    [finalArray addObject:currentMedia];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([finalArray count] > 0)
                {
                    completionBlock(finalArray);
                } else {
                    failureBlock(errorString);
                }
            });
        }
    });
    
}

- (void)getVideoDetailsForIDs:(NSArray*)videoIDs
              completionBlock:(void(^)(NSArray* videoArray))completionBlock
                 failureBlock:(void(^)(NSString* error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSMutableArray *finalArray = [NSMutableArray new];
            //NSMutableDictionary *rootInfo = [NSMutableDictionary new];
            __block NSString *errorString = @"";
            
            for (NSString *videoID in videoIDs) {
                
                NSString *url = [self playerURL];
                DLog(@"url: %@ videoID: %@", url, videoID);
                //get the post body from the url above, gets the initial raw info we work with
                NSDictionary *params = [self paramsForVideo:videoID];
                NSString *body = [self stringFromPostRequest:url withParams:params];
                NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
                NSError *error = nil;
                KBYTMedia *currentMedia = [[KBYTMedia alloc] initWithJSON:jsonDict error:&error];
                if(currentMedia){
                    [finalArray addObject:currentMedia];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([finalArray count] > 0)
                {
                    completionBlock(finalArray);
                } else {
                    failureBlock(errorString);
                }
            });
        }
    });
    
}

#pragma mark utility methods


- (void)importFileWithJO:(NSString *)theFile duration:(NSInteger)duration {
    #if TARGET_OS_IOS
    NSDictionary *info = @{@"filePath": theFile, @"duration": [NSNumber numberWithInteger:duration]};
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.importscience"];
    [center sendMessageName:@"org.nito.importscience.import" userInfo:info];
#endif
}



//useful display details based on the itag
+ (NSDictionary *)formatFromTag:(NSInteger)tag {
    NSDictionary *dict = nil;
    switch (tag) {
            //MP4
        case 38: dict = @{@"format": @"4K MP4", @"height": @2304, @"extension": @"mp4"}; break;
        case 37: dict = @{@"format": @"1080p MP4", @"height": @1080, @"extension": @"mp4"}; break;
        case 22: dict = @{@"format": @"720p MP4", @"height": @720, @"extension": @"mp4"}; break;
        case 18: dict = @{@"format": @"360p MP4", @"height": @360, @"extension": @"mp4"}; break;
            
            /*
             //FLV
             case 35: dict = @{@"format": @"480p FLV", @"height": @480, @"extension": @"flv"}; break;
             case 34: dict = @{@"format": @"360p FLV", @"height": @360, @"extension": @"flv"}; break;
             case 6: dict = @{@"format": @"270p FLV", @"height": @270, @"extension": @"flv"}; break;
             case 5: dict = @{@"format": @"240p FLV", @"height": @240, @"extension": @"flv"}; break;
             //WebM
             case 46: dict = @{@"format": @"1080p WebM", @"height": @1080, @"extension": @"webm"}; break;
             case 45: dict = @{@"format": @"720p WebM", @"height": @720, @"extension": @"webm"}; break;
             case 44: dict = @{@"format": @"480p WebM", @"height": @480, @"extension": @"webm"}; break;
             case 43: dict = @{@"format": @"360p WebM", @"height": @360, @"extension": @"webm"}; break;
             //3gp
             case 36: dict = @{@"format": @"320p 3GP", @"height": @320, @"extension": @"3gp"}; break;
             case 17: dict = @{@"format": @"176p 3GP", @"height": @176, @"extension": @"3gp"}; break;
             
             
             case 137: dict = @{@"format": @"1080p M4V", @"height": @1080, @"extension": @"m4v", @"quality": @"adaptive"}; break;
             case 138: dict = @{@"format": @"4K M4V", @"height": @2160, @"extension": @"m4v", @"quality": @"adaptive"}; break;
             case 264: dict = @{@"format": @"1440p M4v", @"height": @1440, @"extension": @"m4v", @"quality": @"adaptive"}; break;
             
             case 266: dict = @{@"format": @"4K M4V", @"height": @2160, @"extension": @"m4v", @"quality": @"adaptive"}; break;
             
             case 299: dict = @{@"format": @"1080p HFR M4V", @"height": @1080, @"extension": @"m4v", @"quality": @"adaptive"}; break;
             */
        case 140: dict = @{@"format": @"128K AAC M4A", @"height": @0, @"extension": @"aac", @"quality": @"adaptive"}; break;
        case 141: dict = @{@"format": @"256K AAC M4A", @"height": @0, @"extension": @"aac", @"quality": @"adaptive"}; break;
            /*
             //adaptive
             
             case 133: dict = @{@"format": @"240p MP4", @"height": @240, @"extension": @"mp4", @"quality": @"adaptive"}; break;
             case 134: dict = @{@"format": @"360p MP4", @"height": @360, @"extension": @"mp4", @"quality": @"adaptive"}; break;
             case 135: dict = @{@"format": @"480p MP4", @"height": @480, @"extension": @"mp4", @"quality": @"adaptive"}; break;
             case 136: dict = @{@"format": @"720p MP4", @"height": @720, @"extension": @"mp4", @"quality": @"adaptive"}; break;
             case 160: dict = @{@"format": @"144p MP4", @"height": @144, @"extension": @"mp4", @"quality": @"adaptive"}; break;
             
             case 242: dict = @{@"format": @"240p WebM", @"height": @240, @"extension": @"WebM", @"quality": @"adaptive"}; break;
             case 243: dict = @{@"format": @"360p WebM", @"height": @360, @"extension": @"WebM", @"quality": @"adaptive"}; break;
             case 244: dict = @{@"format": @"480p WebM", @"height": @480, @"extension": @"WebM", @"quality": @"adaptive"}; break;
             case 247: dict = @{@"format": @"720p WebM", @"height": @720, @"extension": @"WebM", @"quality": @"adaptive"}; break;
             case 278: dict = @{@"format": @"144p WebM", @"height": @144, @"extension": @"WebM", @"quality": @"adaptive"}; break;
             
             case 298: dict = @{@"format": @"720p HFR MP4", @"height": @720, @"extension": @"mp4", @"quality": @"adaptive"}; break;
             
             
             case 302: dict = @{@"format": @"720p HFR WebM", @"height": @720, @"extension": @"WebM", @"quality": @"adaptive"}; break;
             case 303: dict = @{@"format": @"1080p HFR WebM", @"height": @1080, @"extension": @"WebM", @"quality": @"adaptive"}; break;
             
             //audio
             
             case 171: dict = @{@"format": @"128K Vorbis WebM", @"height": @0, @"extension": @"WebMa", @"quality": @"adaptive"}; break;
             case 249: dict = @{@"format": @"48K Opus WebM", @"height": @0, @"extension": @"WebMa", @"quality": @"adaptive"}; break;
             case 250: dict = @{@"format": @"64K Opus WebM", @"height": @0, @"extension": @"WebMa", @"quality": @"adaptive"}; break;
             case 251: dict = @{@"format": @"160K Opus WebM", @"height": @0, @"extension": @"WebMa", @"quality": @"adaptive"}; break;
             */
            /*
             136=720p MP4
             247=720p WebM
             135=480p MP4
             244=480p WebM
             134=360p MP4
             243=360p WebM
             133=240p MP4
             242=240p WebM
             160=144p MP4
             278=144p WebM
             
             140=AAC M4A 128K
             171=WebM Vorbis 128
             249=WebM Opus 48
             250=WebM Opus 64
             251=WebM Opus 160
             
             299=1080p HFR MP4
             303=1080p HFR WebM
             298=720P HFR MP4
             302=720P HFR VP9 WebM*/
            
        default:
            break;
    }
    
    return dict;
}


/**
 
 this function will take the key array and splice it from the starting index to the end of the string with the value 3
 would change:
 105105282D9AD56125199603D23E2C93F04C9D2237A.B8A82DC92F00EF86757325D88E778BC5D08FC252252 to
 105282D9AD56125199603D23E2C93F04C9D2237A.B8A82DC92F00EF86757325D88E778BC5D08FC252252
 
 */

- (NSMutableArray *)sliceArray:(NSArray *)theArray atIndex:(int)theIndex {
    NSRange theRange = NSMakeRange(theIndex, theArray.count-theIndex);
    return [[theArray subarrayWithRange:theRange] mutableCopy];
}

/*
 
 take an array and reverse it, the mutable copy thing probably isnt very efficient but a necessary? evil to
 retain mutability
 
 */

- (NSMutableArray *)reversedArray:(NSArray *)theArray {
    return [[[theArray reverseObjectEnumerator] allObjects] mutableCopy];
}

/*
 
 take the value at index 0 and swap it with theIndex
 
 */

- (NSMutableArray *)swapCharacterAtIndex:(int)theIndex inArray:(NSMutableArray *)theArray {
    [theArray exchangeObjectAtIndex:0 withObjectAtIndex:theIndex];
    return theArray;
    
}


@end
