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
#ifndef SHELF_EXT
#import "TYAuthUserManager.h"
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
    return [NSString stringWithFormat:@"%@ title: %@ content count: %lu", desc,_title, _content.count];
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
    //NSLog(@"[tuyu] new channel: %@", channel.videos);
    //NSLog(@"[tuyu] current videos: %@", self.videos);
    [newVideos addObjectsFromArray:channel.videos];
    self.continuationToken = channel.continuationToken;
    self.videos = newVideos;
}

- (NSArray <KBYTSearchResult *>*)allSortedItems {
    if (self.videos.count > 0 && self.playlists.count > 0){
        NSMutableArray *_newArray = [[self videos] mutableCopy];
        //NSLog(@"[tuyu] playlists: %@", self.playlists);
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
    self.continuationToken = cc[@"token"];
    //NSLog(@"cc: %@", cc);
    if (filter == KBYTSearchTypeAll) {
        __block NSMutableArray *videoResults = [NSMutableArray new];
        recursiveObjectsLike(@"videoRenderer", jsonDict, videos);
        [videos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            KBYTSearchResult *searchItem = [[KBYourTube sharedInstance] searchResultFromVideoRenderer:obj];
            [videoResults addObject:searchItem];
        }];
        self.videos = videoResults;
    }
    
    //NSLog(@"[tuyu] playlist count: %lu", playlists.count);
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
            if (!title){
                //NSLog(@"[tuyu] weird pl item: %@", current);
                //NSLog(@"[tuyu] pl item: %@", searchItem);
            }
            /*
             NSString *outputFile = [[NSHomeDirectory() stringByAppendingPathComponent:searchItem.title] stringByAppendingPathExtension:@"plist"];
             [current writeToFile:outputFile atomically:true];
             NSLog(@"[tuyu] writing playlist: %@", outputFile);
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
            if (!title){
                //NSLog(@"[tuyu] weird channel item: %@", current);
            }
            /*
             NSString *outputFile = [[NSHomeDirectory() stringByAppendingPathComponent:searchItem.title] stringByAppendingPathExtension:@"plist"];
             [current writeToFile:outputFile atomically:true];
             NSLog(@"[tuyu] writing channel: %@", outputFile);*/
            [channelResults addObject:searchItem];
        }];
        self.channels = channelResults;
    }

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

- (id)initWithYTChannelDictionary:(NSDictionary *)channelDict {
    KBYTSearchResult *channel = [KBYTSearchResult new];
    channel.videoId = [channelDict recursiveObjectForKey:@"resourceId"][@"channelId"];
    channel.channelId = channelDict[@"snippet"][@"channelId"];
    channel.title = [channelDict recursiveObjectForKey:@"title"];
    channel.details = [channelDict recursiveObjectForKey:@"description"];
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
    playlist.imagePath = [playlistDict recursiveObjectForKey:@"thumbnails"][@"high"][@"url"];
    playlist.resultType = kYTSearchResultTypePlaylist;
    playlist.continuationToken = playlistDict[@"nextPageToken"];
    return playlist;
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
    return [[self dictionaryValue] description];
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
    KBYTStream *firstStream = [[self streams] lastObject];
    //NSLog(@"[tuyu] firstStream: %@ in %@", [self streams], NSStringFromSelector(_cmd));
   
    YTPlayerItem *mediaItem = [[YTPlayerItem alloc] initWithURL:firstStream.url];
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


- (id)initWithJSON:(NSDictionary *)jsonDict {
    self = [super init];
    if ([self processJSON:jsonDict] == true) {
        return self;
    }
    return nil;
}

- (BOOL)processJSON:(NSDictionary *)jsonDict {
    NSDictionary *streamingData = jsonDict[@"streamingData"];
    NSDictionary *videoDetails = jsonDict[@"videoDetails"];
    self.author = videoDetails[@"author"];
    self.title = videoDetails[@"title"];
    self.videoId = videoDetails[@"videoId"];
    self.views = videoDetails[@"viewCount"];
    self.duration = videoDetails[@"lengthSeconds"];
    self.details = videoDetails[@"shortDescription"];
    NSArray *imageArray = videoDetails[@"thumbnail"][@"thumbnails"];
    self.keywords = [videoDetails[@"keywords"] componentsJoinedByString:@","];
    NSMutableDictionary *images = [NSMutableDictionary new];
    NSInteger imageCount = imageArray.count; //TODO make sure there are actually that many images
    images[@"high"] = imageArray.lastObject[@"url"];
    images[@"medium"] = imageArray[imageCount-2][@"url"];
    images[@"standard"] = imageArray[imageCount-3][@"url"];
    self.images = images;
    NSMutableArray *videoArray = [NSMutableArray new];
    NSArray *formats = streamingData[@"formats"];
    //NSLog(@"adaptiveFormats: %@", adaptiveFormats);
    //NSLog(@"formats: %@", formats);
    /*
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
    }];*/
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
    //NSString *desc = [[KBYourTube sharedInstance] videoDetailsFromID:videoID][@"description"];
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
    return @{@"title": self.title, @"author": self.author, @"keywords": self.keywords, @"videoID": self.videoId, @"views": self.views, @"duration": self.duration, @"images": self.images, @"streams": self.streams, @"details": self.details, @"expireTime": [NSNumber numberWithInteger:self.expireTime], @"isExpired": [self expiredString]};
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

- (NSDictionary *)paramsForVideo:(NSString *)videoID {
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
#ifndef SHELF_EXT
    return [[TYAuthUserManager sharedInstance] authorized];
#endif
    ONOXMLDocument *xmlDoc = [self documentFromURL:@"https://www.youtube.com/feed/history"];
    ONOXMLElement *root = [xmlDoc rootElement];
    ONOXMLElement * displayMessage = [root firstChildWithXPath:@"//div[contains(@class, 'display-message')]"];
    //[root firstChildWithXPath:@"//div[contains(@class, 'yt-formatted-string')]"]
    NSString *displayMessageString = [displayMessage stringValue];
    NSLog(@"dms: %@", displayMessageString);
    if (displayMessageString.length == 0 || displayMessageString == nil) {
       // [TYAuthUserManager]
        return true;
    }
    return false;

}

- (NSInteger)videoCountForChannel:(NSString *)channelID {
    DLog(@"videoCountForChannel: %@", channelID);
    //channels-browse-content-grid
    //channels-content-item
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@/videos", channelID]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    NSArray *objects = [(NSEnumerator *)[canon XPath:@".//li[contains(@class, 'channels-content-item')]"] allObjects];
    return [objects count];
}

- (NSInteger)videoCountForUserName:(NSString *)channelID {
    //channels-browse-content-grid
    //channels-content-item
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/user/%@/videos", channelID]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    NSArray *objects = [(NSEnumerator *)[canon XPath:@".//li[contains(@class, 'channels-content-item')]"] allObjects];
    return [objects count];
}


- (void)getUserDetailsDictionaryWithCompletionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                                       failureBlock:(void(^)(NSString *error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            BOOL signedIn = [self isSignedIn];
            NSString *errorString = @"Unknown error occurred";
            __block NSMutableDictionary *returnDict = [NSMutableDictionary new];
            __block NSMutableArray *itemArray = [NSMutableArray new];
            if (signedIn == true) {
                
#ifndef SHELF_EXT
                TYAuthUserManager *authManager = [TYAuthUserManager sharedInstance];
                [authManager getPlaylistsWithCompletion:^(NSArray<KBYTSearchResult *> *playlists, NSString *error) {
                    if (playlists.count > 0) {
                        [itemArray addObjectsFromArray:playlists];
                        if (![[returnDict allKeys] containsObject:@"channelID"]){
                            returnDict[@"channelID"] = [playlists firstObject].channelId;
                        }
                        returnDict[@"userName"] = [playlists firstObject].author;
                        
                    }
                    [authManager getChannelListWithCompletion:^(NSArray<KBYTSearchResult *> *channels, NSString *error) {
                        if (channels.count > 0) {
                            returnDict[@"channels"] = channels;
                            if (![[returnDict allKeys] containsObject:@"channelID"]){
                                returnDict[@"channelID"] = [channels firstObject].channelId;
                            }
                        }
                        NSString *userName = returnDict[@"userName"];
                        NSString *channelID = returnDict[@"channelID"];
                        //NSLog(@"[tuyu] rd: %@", returnDict);
                        KBYTSearchResult *userChannel = [KBYTSearchResult new];
                        userChannel.title = @"Your channel";
                        userChannel.author = userName;
                        userChannel.videoId = channelID;
                        //userChannel.details = [NSString stringWithFormat:@"%lu videos", channelVideoCount];
                        //userChannel.imagePath = ourUserDetails[@"profileImage"];
                        userChannel.resultType =kYTSearchResultTypeChannel;
                        [itemArray addObject:userChannel];
                        returnDict[@"results"] = itemArray;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            if (returnDict != nil)
                            {
                                completionBlock(returnDict);
                            } else {
                                failureBlock(errorString);
                            }
                            
                            
                        });
                    }];
                }];
                
                return;
                
#else
                
                NSDictionary *channelDict = [self channelIDAndWatchLaterCount];
                NSLog(@"[yourTubeiOS] channelDict: %@", channelDict);
                NSString *channelID = channelDict[@"channelID"];
                NSDictionary *ourUserDetails = [self userDetailsFromChannelURL:channelID];
                if (ourUserDetails == nil)
                {
                    NSLog(@"[yourTubeiOS] false positive on signed in, bail");
                    failureBlock(@"false positive on signed in");
                    return;
                }
                NSString *userName = ourUserDetails[@"username"];
                NSInteger channelVideoCount = [self videoCountForUserName:userName];
                NSMutableArray *itemArray = nil;
                NSArray *channels = nil;
                if ([[ourUserDetails allKeys] containsObject:@"altUserName"])
                {
                    channelVideoCount = [self videoCountForChannel:userName];
                    itemArray = [[NSMutableArray alloc] initWithArray:[self playlistArrayFromChannel:userName]];
                    channels = [self channelArrayFromChannel:userName];
                    returnDict[@"altUserName"] = ourUserDetails[@"altUserName"];
                } else {
                    itemArray = [[NSMutableArray alloc] initWithArray:[self playlistArrayFromUserName:userName]];
                    channels = [self channelArrayFromUserName:userName];
                }
                
                //NSArray *playlists = [self playlistArrayFromUserName:userName];
                KBYTSearchResult *userChannel = [KBYTSearchResult new];
                userChannel.title = @"Your channel";
                userChannel.author = userName;
                userChannel.videoId = channelID;
                userChannel.details = [NSString stringWithFormat:@"%lu videos", channelVideoCount];
                userChannel.imagePath = ourUserDetails[@"profileImage"];
                userChannel.resultType =kYTSearchResultTypeChannel;
                [itemArray addObject:userChannel];
                
                NSInteger wlCount = [channelDict[@"wlCount"] integerValue];
                if (wlCount > 0){
                KBYTSearchResult *wlPl = [KBYTSearchResult new];
                wlPl.author = userName;
                wlPl.videoId = @"WL";
                wlPl.details = [NSString stringWithFormat:@"%lu videos", wlCount];
                wlPl.title = @"Watch later";
                wlPl.imagePath = ourUserDetails[@"profileImage"];
                wlPl.resultType =kYTSearchResultTypePlaylist;
                
                [itemArray addObject:wlPl];
                
                }
                //NSArray *channelVideos = [self videoChannelsList:channelID][@"results"];
                //DLog(@"channels: %@", channels);
                
                returnDict[@"userName"] = userName;
                returnDict[@"results"] = itemArray;
                returnDict[@"profileImage"] = ourUserDetails[@"profileImage"];
                returnDict[@"channelID"]= channelID;
                if (channels != nil)
                {
                    returnDict[@"channels"] = channels;
                    
                }
                
#endif
                
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

- (NSDictionary *)channelIDAndWatchLaterCount {
    ONOXMLDocument *xmlDoc = [self documentFromURL:@"https://m.youtube.com"];
    ONOXMLElement *root = [xmlDoc rootElement];
   /* NSArray *itemCounts = [(NSEnumerator *)[root XPath:@".//span[contains(@class, 'yt-valign-container guide-count-value')]"] allObjects];
    NSString *watchLaterCount = @"1";
    if (itemCounts.count > 1) {
    
        watchLaterCount = [[itemCounts objectAtIndex:1] stringValue];
    }
    */
    NSString *watchLaterCount = [NSString stringWithFormat:@"%lu", [self watchLaterCount]];
    ONOXMLElement *guideSection = [root firstChildWithXPath:@"//li[contains(@class, 'guide-section')]"];
    NSArray *allObjects = [(NSEnumerator *)[guideSection XPath:@".//a[contains(@class, 'guide-item')]"] allObjects];
    if ([allObjects count] > 1) {
        ONOXMLElement *channelElement = [allObjects objectAtIndex:1];
        if ([channelElement valueForAttribute:@"href"] != nil && watchLaterCount != nil)
        {
        return @{@"channelID": [[channelElement valueForAttribute:@"href"] lastPathComponent], @"wlCount": watchLaterCount};
        }
    }
    
    //<span class="yt-valign-container guide-count-value">4</span>
    return nil;
}

- (NSString *)channelID {
    ONOXMLDocument *xmlDoc = [self documentFromURL:@"https://m.youtube.com"];
    ONOXMLElement *root = [xmlDoc rootElement];
    ONOXMLElement *guideSection = [root firstChildWithXPath:@"//li[contains(@class, 'guide-section')]"];
    NSArray *allObjects = [(NSEnumerator *)[guideSection XPath:@".//a[contains(@class, 'guide-item')]"] allObjects];
    if ([allObjects count] > 1) {
        ONOXMLElement *channelElement = [allObjects objectAtIndex:1];
        return [[channelElement valueForAttribute:@"href"] lastPathComponent];
    }
    return nil;
}

/*
 
 <title>  nito
 - YouTube</title><link rel="canonical" href="https://www.youtube.com/user/suckpump"><link rel="alternate" media="handheld" href="https://m.youtube.com/channel/UCiuFEQ2-YiaW97Uzu00bOZQ"><link rel="alternate" media="only screen and (max-width: 640px)" href="https://m.youtube.com/channel/UCiuFEQ2-YiaW97Uzu00bOZQ">      <meta name="title" content="nito">
 
 <meta name="description" content="">
 
 
 vs
 
 <title>  Kevin Bradley
 - YouTube</title><link rel="canonical" href="https://www.youtube.com/channel/UC-d63ZntP27p917VXU-VFiA"><link rel="alternate" media="handheld" href="https://m.youtube.com/channel/UC-d63ZntP27p917VXU-VFiA"><link rel="alternate" media="only screen and (max-width: 640px)" href="https://m.youtube.com/channel/UC-d63ZntP27p917VXU-VFiA">      <meta name="title" content="Kevin Bradley">
 
 <meta name="description" content="">
 
 */

- (NSDictionary *)userDetailsFromChannelURL:(NSString *)channelURL {
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@", channelURL]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//link[contains(@rel, 'canonical')]"];
    
    //<img class="channel-header-profile-image" src="//i.ytimg.com/i/iuFEQ2-YiaW97Uzu00bOZQ/mq1.jpg?v=564b8e92" title="nito" alt="nito">
    NSString *profileImage = [[root firstChildWithXPath:@"//img[contains(@class, 'channel-header-profile-image')]"] valueForAttribute:@"src"];
    
    NSString *altUserName = [[[root firstChildWithXPath:@"//meta"] valueForAttribute:@"content"] lowercaseString];
    
    //get the high quality version instead of the mq crappy one.
    profileImage = [profileImage stringByReplacingOccurrencesOfString:@"/mq" withString:@"/hq"];
    
    
    if (canon != nil & profileImage != nil) {
        
        NSMutableDictionary *userDict = [NSMutableDictionary new];
        
        NSString *href = [canon valueForAttribute:@"href"];
        if ([href containsString:@"channel"])
        {
            userDict[@"altUserName"] = altUserName;
        }
        userDict[@"username"] = [href lastPathComponent];
        userDict[@"profileImage"] = [NSString stringWithFormat:@"https:%@", profileImage];
        return userDict;
       // return @{@"username": [[canon valueForAttribute:@"href"] lastPathComponent], @"profileImage": [NSString stringWithFormat:@"https:%@", profileImage] } ;
    }
    
    return nil;
}

- (NSString *)userNameFromChannelURL:(NSString *)channelURL {
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@", channelURL]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//link[contains(@rel, 'canonical')]"];
    return [[canon valueForAttribute:@"href"] lastPathComponent];
}

- (NSDictionary *)videoChannelsList:(NSString *)channelID {
    // NSString *requestString = @"https://www.youtube.com/channel/UC-9-kyTW8ZkZNDHQJ6FgpwQ/videos";
    NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/channel/%@/videos", channelID];
    NSString *rawRequestResult = [self stringFromRequest:requestString];
    ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
    ONOXMLElement *root = [xmlDoc rootElement];
    //NSLog(@"root element: %@", root);
    
    ONOXMLElement *videosElement = [root firstChildWithXPath:@"//*[contains(@class, 'channels-browse-content-grid')]"];
    id videoEnum = [videosElement XPath:@"//div[contains(@class, 'yt-lockup-video')]"];
    ONOXMLElement *currentElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    NSMutableDictionary *outputDict = [NSMutableDictionary new];
    
    ONOXMLElement *channelNameElement = [root firstChildWithXPath:@"//meta[contains(@name, 'title')]"];
    ONOXMLElement *channelDescElement = [root firstChildWithXPath:@"//meta[contains(@name, 'description')]"];
    ONOXMLElement *channelKeywordsElement = [root firstChildWithXPath:@"//meta[contains(@name, 'keywords')]"];
    if (channelNameElement != nil) {
        outputDict[@"name"] = [channelNameElement valueForAttribute:@"content"];
    }
    if (channelDescElement != nil) {
        outputDict[@"description"] = [channelDescElement valueForAttribute:@"content"];
    }
    if (channelKeywordsElement != nil) {
        outputDict[@"keywords"] = [channelKeywordsElement valueForAttribute:@"content"];
    }
    
    while (currentElement = [videoEnum nextObject]) {
        //NSMutableDictionary *scienceDict = [NSMutableDictionary new];
        KBYTSearchResult *result = [KBYTSearchResult new];
        NSString *videoID = [currentElement valueForAttribute:@"data-context-item-id"];
        if (videoID != nil)
        {
            result.videoId = videoID;
        }
        ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-simple')]"] children] firstObject];
        ONOXMLElement *lengthElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
        ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"];
        ;
        ONOXMLElement *descElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-description')]"];
        ONOXMLElement *authorElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-byline')]"] children] firstObject];
        ONOXMLElement *ageAndViewsElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-meta-info')]"];//yt-lockup-meta-info
        NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
        if (imagePath == nil)
        {
            imagePath = [thumbNailElement valueForAttribute:@"src"];
        }
        if (imagePath != nil)
        {
            if ([imagePath containsString:@"https:"])
            {
                result.imagePath = imagePath;
            } else {
                result.imagePath = [@"https:" stringByAppendingString:imagePath];
            }
        }
        if (lengthElement != nil)
            result.duration = lengthElement.stringValue;
        
        if (titleElement != nil)
            result.title = [[titleElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        NSString *vdesc = [[descElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        if (vdesc != nil)
        {
            result.details = [vdesc stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        
        if (authorElement != nil)
        {
            
            result.author = [authorElement stringValue];
        }
        for (ONOXMLElement *currentElement in [ageAndViewsElement children])
        {
            NSString *currentValue = [currentElement stringValue];
            if ([currentValue containsString:@"ago"]) //age
            {
                result.age = currentValue;
            } else if ([currentValue containsString:@"views"])
            {
                result.views = [[currentValue componentsSeparatedByString:@" "] firstObject];
            }
        }
        
        if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
        {
            //NSLog(@"result: %@", result);
            [finalArray addObject:result];
        } else {
            result = nil;
        }
        if ([finalArray count] > 0)
        {
            ONOXMLElement *loadMoreButton = [root firstChildWithXPath:@"//button[contains(@class, 'load-more-button')]"];
            NSString *loadMoreHREF = [loadMoreButton valueForAttribute:@"data-uix-load-more-href"];
            if (loadMoreHREF != nil){
                outputDict[@"loadMoreREF"] = loadMoreHREF;
            }
            outputDict[@"results"] = finalArray;
            outputDict[@"resultCount"] = [NSNumber numberWithInteger:[finalArray count]];
            NSInteger pageCount = 1;
            outputDict[@"pageCount"] = [NSNumber numberWithInteger:pageCount];
        }
    }
    return outputDict;
}

- (NSArray *)playlistArrayFromChannel:(NSString *)channel {
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@/playlists?sort=da&flow=grid&view=1", channel]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *playlistGroup = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    id playlistEnum = [playlistGroup XPath:@".//li[contains(@class, 'channels-content-item')]"];
    ONOXMLElement *playlistElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    while (playlistElement = [playlistEnum  nextObject]) {
        ONOXMLElement *thumbElement = [[[playlistElement firstChildWithXPath:@".//span[contains(@class, 'yt-thumb-clip')]"] children ] firstObject];
        ONOXMLElement *playlistTitleElement = [[[playlistElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"]children ] firstObject] ;
        ONOXMLElement *videoCountElement = [[[playlistElement firstChildWithXPath:@".//*[contains(@class, 'formatted-video-count-label')]"] children] firstObject];
        NSString *thumbPath = [thumbElement valueForAttribute:@"src"];
        NSString *playlistTitle = [playlistTitleElement valueForAttribute:@"title"];
        NSString *playlistURL = [[[playlistTitleElement valueForAttribute:@"href"] componentsSeparatedByString:@"="] lastObject];
        NSString *videoCount = [videoCountElement stringValue];
        KBYTSearchResult *result = [KBYTSearchResult new];
        if ([thumbPath rangeOfString:@"https"].location == NSNotFound)
        {
            result.imagePath = [NSString stringWithFormat:@"https:%@", thumbPath];
        } else {
            result.imagePath = thumbPath;
        }
        //DLog(@"ip: %@", result.imagePath);
        result.title = playlistTitle;
        result.author = channel;
        result.details = videoCount;
        result.videoId = playlistURL;
        result.resultType =kYTSearchResultTypePlaylist;
        //NSDictionary *playlistItem = @{@"thumbURL": [NSString stringWithFormat:@"https:%@", thumbPath], @"title": playlistTitle, @"URL": playlistURL, @"videoCount": videoCount};
        [finalArray addObject:result];
        
    }
    return finalArray;
}

- (NSArray *)playlistArrayFromUserName:(NSString *)userName {
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/%@/playlists?sort=da&flow=grid&view=1", userName]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *playlistGroup = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    id playlistEnum = [playlistGroup XPath:@".//li[contains(@class, 'channels-content-item')]"];
    ONOXMLElement *playlistElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    while (playlistElement = [playlistEnum  nextObject]) {
        ONOXMLElement *thumbElement = [[[playlistElement firstChildWithXPath:@".//span[contains(@class, 'yt-thumb-clip')]"] children ] firstObject];
        ONOXMLElement *playlistTitleElement = [[[playlistElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"]children ] firstObject] ;
        ONOXMLElement *videoCountElement = [[[playlistElement firstChildWithXPath:@".//*[contains(@class, 'formatted-video-count-label')]"] children] firstObject];
        NSString *thumbPath = [thumbElement valueForAttribute:@"src"];
        NSString *playlistTitle = [playlistTitleElement valueForAttribute:@"title"];
        NSString *playlistURL = [[[playlistTitleElement valueForAttribute:@"href"] componentsSeparatedByString:@"="] lastObject];
        NSString *videoCount = [videoCountElement stringValue];
        KBYTSearchResult *result = [KBYTSearchResult new];
        if ([thumbPath rangeOfString:@"https"].location == NSNotFound)
        {
            result.imagePath = [NSString stringWithFormat:@"https:%@", thumbPath];
        } else {
            result.imagePath = thumbPath;
        }
        //DLog(@"ip: %@", result.imagePath);
        result.title = playlistTitle;
        result.author = userName;
        result.details = videoCount;
        result.videoId = playlistURL;
        result.resultType =kYTSearchResultTypePlaylist;
        //NSDictionary *playlistItem = @{@"thumbURL": [NSString stringWithFormat:@"https:%@", thumbPath], @"title": playlistTitle, @"URL": playlistURL, @"videoCount": videoCount};
        [finalArray addObject:result];
        
    }
    return finalArray;
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

- (NSDictionary *)videoDetailsFromID:(NSString *)videoID {
    NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", videoID];
    NSString *request = [self stringFromRequest:requestString];
    ONOXMLDocument *document = [ONOXMLDocument HTMLDocumentWithString:request encoding:NSUTF8StringEncoding error:nil];
    ONOXMLElement *root = [document rootElement];
    NSString *XPath = @"//div/meta";
    id titleEnum = [root XPath:XPath];
    
    NSMutableDictionary *detailsDict = [NSMutableDictionary new];
    
    id theObject = nil;
    while (theObject = [titleEnum nextObject]) {
        // NSLog(@"keys: %@", [theObject attributes]);
        NSString *key = [theObject valueForAttribute:@"itemprop"];
        NSString *content = [theObject valueForAttribute:@"content"];
        detailsDict[key] = content;
        
    }
    
    ONOXMLElement *viewElement = [root firstChildWithXPath:@"//div[contains(normalize-space(@class), 'watch-view-count')]"];
    ONOXMLElement *thumbElement = [root firstChildWithXPath:@"//link[contains(normalize-space(@itemprop), 'thumbnailUrl')]"];
    ONOXMLElement *userElement = [root firstChildWithXPath:@"//link[contains(normalize-space(@href), '/user/')]"];
    ONOXMLElement *keywordElement = [root firstChildWithXPath:@"//meta[contains(@name, 'keywords')]"];
    
    if (keywordElement != nil) {
        
        detailsDict[@"keywords"] = [keywordElement valueForAttribute:@"content"];
        
    }
    if (viewElement != nil)
        detailsDict[@"views"] = viewElement.stringValue;
    
    if (thumbElement != nil)
        detailsDict[@"thumbnail"] = [thumbElement valueForAttribute:@"href"];
    
    if (userElement != nil)
        detailsDict[@"author"] = [[userElement valueForAttribute:@"href"] lastPathComponent];
    
    return detailsDict;
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

/*
 
 everything before <ol id="item-section" is mostly useless, and everything after the end </ol> is also
 useless. this trims down to just the pertinent info and feeds back the raw string for processing.
 
 */
//https://www.youtube.com/playlist?list=PLkijzJW7zLBVjWGGtcA_Q2Vu8UuG5kLvt

- (NSString *)rawYTFromHTML:(NSString *)html {
    
    NSScanner *theScanner;
    NSString *text = nil;
    theScanner = [NSScanner scannerWithString:html];
    [theScanner scanUpToString:@"<ol id=\"item-section" intoString:NULL];
    [theScanner scanUpToString:@"</ol>" intoString:&text] ;
    return [text stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
}

- (NSInteger)watchLaterCount {
    NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/playlist?list=%@", @"WL"];
    NSString *rawRequestResult = [self stringFromRequest:requestString];
    ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
    ONOXMLElement *root = [xmlDoc rootElement];
    //NSLog(@"root element: %@", root);
    
    ONOXMLElement *videosElement = [root firstChildWithXPath:@"//*[contains(@class, 'pl-video-list')]"];
    id videoEnum = [videosElement XPath:@".//*[contains(@class, 'pl-video')]"];
    return [[videoEnum allObjects]count];
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
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForPlaylist:listID continuation:continuationToken];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            //NSLog(@"body: %@ for: %@ %@", jsonDict, url, params);
            //        DLog(@"array: %lu", vrArray.count);
            [jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"drake.plist"] atomically:true];
            __block NSMutableArray *videos = [NSMutableArray new];
            KBYTPlaylist *playlist = [KBYTPlaylist new];
            id cc = [jsonDict recursiveObjectForKey:@"continuationCommand"];
            playlist.playlistID = listID;
            //NSLog(@"[tuyu] cc: %@", cc);
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
                            //NSLog(@"[tuyu] no vr: %@", obj);
                            //NSLog(@"[tuyu] do we have a message?: %@", message);
                        } else {
                            NSLog(@"[tuyu] no vr: %@", obj);
                        }
                    }
                }];
                //playlist.videos = videos;
            } else {
                NSArray *continuationItems = [jsonDict recursiveObjectForKey:@"continuationItems"];
                if (continuationItems) {
                    //NSLog(@"[tuyu] we found continuation items: %lu", continuationItems.count);
                    [continuationItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        //NSLog(@"%@", obj[@"playlistPanelVideoRenderer"]);
                        NSDictionary *current = [obj recursiveObjectLikeKey:@"videoRenderer"];
                        if (current) {
                            
                            KBYTSearchResult *searchItem = [self searchResultFromVideoRenderer:current];
                            [videoIds addObject:searchItem.videoId];
                            [videos addObject:searchItem];
                        } else {
                            //NSLog(@"[tuyu] no vr: %@", obj);
                            NSString *message = [obj recursiveObjectForKey:@"simpleText"];
                            if (message){
                                //NSLog(@"[tuyu] do we have a message?: %@", message);
                            } else {
                                NSLog(@"[tuyu] no vr: %@", obj);
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


- (void)loadMorePlaylistVideosFromHREF:(NSString *)loadMoreLink
                       completionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                          failureBlock:(void(^)(NSString *error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        
        @autoreleasepool {
            
            NSString *requestString = [@"https://m.youtube.com" stringByAppendingPathComponent:loadMoreLink];
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            NSData *JSONData = [rawRequestResult dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingAllowFragments error:nil];
            
            NSString *rawHTML = jsonDict[@"content_html"];
            NSString *loadMoreHTML = jsonDict[@"load_more_widget_html"];
            ONOXMLDocument *loadMoreDoc = [ONOXMLDocument HTMLDocumentWithString:loadMoreHTML encoding:NSUTF8StringEncoding error:nil];
            
            
            
            // ONOXMLElement *root = [xmlDoc rootElement];
            
            ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawHTML encoding:NSUTF8StringEncoding error:nil];
            ONOXMLElement *root = [xmlDoc rootElement];
            
            // NSLog(@"rawHTML: %@", root);
            id videoEnum = [root XPath:@".//*[contains(@class, 'pl-video')]"];
            ONOXMLElement *currentElement = nil;
            NSMutableArray *finalArray = [NSMutableArray new];
            NSMutableDictionary *outputDict = [NSMutableDictionary new];
            
            while (currentElement = [videoEnum nextObject])
            {
                //NSMutableDictionary *scienceDict = [NSMutableDictionary new];
                KBYTSearchResult *result = [KBYTSearchResult new];
                result.resultType =kYTSearchResultTypeVideo;
                NSString *videoID = [currentElement valueForAttribute:@"data-video-id"];
                if (videoID != nil)
                {
                    result.videoId = videoID;
                }
                // NSLog(@"currentElement: %@", currentElement);
                NSString *title = [currentElement valueForAttribute:@"data-title"];
                if (title != nil)
                {
                    result.title = title;
                }
                
                
                ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-clip')]"] children] firstObject];
                ONOXMLElement *lengthElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
                ONOXMLElement *authorElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'pl-video-owner')]"] children] firstObject];
                NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                if (imagePath == nil)
                {
                    imagePath = [thumbNailElement valueForAttribute:@"src"];
                }
                if (imagePath != nil)
                {
                    if ([[imagePath lastPathComponent]isEqualToString:@"default.jpg"])
                    {
                        imagePath = [[imagePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"hqdefault.jpg"];
                    }
                    if ([imagePath containsString:@"https:"])
                    {
                        result.imagePath = imagePath;
                    } else {
                        result.imagePath = [@"https:" stringByAppendingString:imagePath];
                    }
                }
                if (lengthElement != nil)
                    result.duration = [lengthElement.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                if (authorElement != nil)
                {
                    result.author = [authorElement stringValue];
                }
                
                if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"] && ![result.title isEqualToString:@"[Deleted Video]"]&& ![result.title isEqualToString:@"[Private Video]"])
                {
                    [finalArray addObject:result];
                } else {
                    result = nil;
                }
                if ([finalArray count] > 0)
                {
                    ONOXMLElement *loadMoreButton = [[loadMoreDoc rootElement] firstChildWithXPath:@"//button[contains(@class, 'load-more-button')]"];
                    NSString *loadMoreHREF = [loadMoreButton valueForAttribute:@"data-uix-load-more-href"];
                    if (loadMoreHREF != nil){
                        outputDict[@"loadMoreREF"] = loadMoreHREF;
                    }
                    outputDict[@"results"] = finalArray;
                    outputDict[@"resultCount"] = [NSNumber numberWithInteger:[finalArray count]];
                    NSInteger pageCount = 1;
                    outputDict[@"pageCount"] = [NSNumber numberWithInteger:pageCount];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([outputDict[@"results"] count] > 0)
                {
                    completionBlock(outputDict);
                } else {
                    failureBlock([NSString stringWithFormat:@"error loading href: %@", loadMoreLink]);
                }
                
            });
            
        }
    });
}

- (void)loadMoreVideosFromHREF:(NSString *)loadMoreLink
               completionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                  failureBlock:(void(^)(NSString *error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        
        @autoreleasepool {
            
            NSString *requestString = [@"https://m.youtube.com" stringByAppendingPathComponent:loadMoreLink];
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            NSData *JSONData = [rawRequestResult dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingAllowFragments error:nil];
            
            NSString *rawHTML = jsonDict[@"content_html"];
            NSString *loadMoreHTML = jsonDict[@"load_more_widget_html"];
            ONOXMLDocument *loadMoreDoc = [ONOXMLDocument HTMLDocumentWithString:loadMoreHTML encoding:NSUTF8StringEncoding error:nil];
            ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawHTML encoding:NSUTF8StringEncoding error:nil];
            ONOXMLElement *root = [xmlDoc rootElement];
            ONOXMLElement *videosElement = [root firstChildWithXPath:@"//ol[contains(@class, 'item-section')]"];
            if (videosElement == nil)
            {
                videosElement = root;
            }
            id videoEnum = [videosElement XPath:@"//div[contains(@class, 'yt-lockup-video')]"];
            ONOXMLElement *currentElement = nil;
            NSMutableArray *finalArray = [NSMutableArray new];
            NSMutableDictionary *outputDict = [NSMutableDictionary new];
            while (currentElement = [videoEnum nextObject])
            {
                KBYTSearchResult *result = [KBYTSearchResult new];
                result.resultType =kYTSearchResultTypeVideo;
                NSString *videoID = [currentElement valueForAttribute:@"data-context-item-id"];
                if (videoID != nil)
                {
                    result.videoId = videoID;
                }
                ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-simple')]"] children] firstObject];
                
                if (thumbNailElement == nil)
                {
                    thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-clip')]"] children] firstObject];
                }
                
                ONOXMLElement *lengthElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
                ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"];
                ;
                ONOXMLElement *descElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-description')]"];
                ONOXMLElement *authorElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-byline')]"] children] firstObject];
                ONOXMLElement *ageAndViewsElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-meta-info')]"];//yt-lockup-meta-info
                NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                if (imagePath == nil)
                {
                    imagePath = [thumbNailElement valueForAttribute:@"src"];
                }
                if (imagePath != nil)
                {
                    if ([imagePath containsString:@"https:"])
                    {
                        result.imagePath = imagePath;
                    } else {
                        result.imagePath = [@"https:" stringByAppendingString:imagePath];
                    }
                }
                if (lengthElement != nil)
                    result.duration = lengthElement.stringValue;
                
                if (titleElement != nil)
                {
                    result.title = [[[titleElement children]firstObject] valueForAttribute:@"title"];
                    //   result.title = [[titleElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                }
                NSString *vdesc = [[descElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                if (vdesc != nil)
                {
                    result.details = [vdesc stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
                
                if (authorElement != nil)
                {
                    result.channelPath = [authorElement valueForAttribute:@"href"];
                    NSArray *pathArray = [result.channelPath componentsSeparatedByString:@"/"];
                    NSString *pathType = pathArray[1];
                    DLog(@"cp: %@ pathType: %@", result.channelPath,pathType);
                    if ([pathType isEqualToString:@"channel"])
                    {
                        result.channelId = pathArray[2];
                        DLog(@"channelID: %@", result.channelId);
                    }
                    
                    result.author = [authorElement stringValue];
                }
                for (ONOXMLElement *currentElement in [ageAndViewsElement children])
                {
                    NSString *currentValue = [currentElement stringValue];
                    if ([currentValue containsString:@"ago"]) //age
                    {
                        result.age = currentValue;
                    } else if ([currentValue containsString:@"views"])
                    {
                        result.views = [[currentValue componentsSeparatedByString:@" "] firstObject];
                    }
                }
                
                if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
                {
                    //NSLog(@"result: %@", result);
                    [finalArray addObject:result];
                } else {
                    result = nil;
                }
                
            }
            if ([finalArray count] > 0)
            {
                //load-more-button
                ONOXMLElement *loadMoreButton = [[loadMoreDoc rootElement] firstChildWithXPath:@"//button[contains(@class, 'load-more-button')]"];
                NSString *loadMoreHREF = [loadMoreButton valueForAttribute:@"data-uix-load-more-href"];
                if (loadMoreHREF != nil){
                    outputDict[@"loadMoreREF"] = loadMoreHREF;
                }
                outputDict[@"results"] = finalArray;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([outputDict[@"results"] count] > 0)
                {
                    completionBlock(outputDict);
                } else {
                    failureBlock([NSString stringWithFormat:@"error loading href: %@", loadMoreLink]);
                }
                
            });
            
        }
    });
}

- (NSArray *)channelArrayFromChannel:(NSString *)userName {
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@/channels?view=56&shelf_id=0", userName]];
    ONOXMLElement *root = [xmlDoct rootElement];
    // NSLog(@"root: %@", root);
    ONOXMLElement *playlistGroup = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    id playlistEnum = [playlistGroup XPath:@".//li[contains(@class, 'channels-content-item')]"];
    ONOXMLElement *playlistElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    while (playlistElement = [playlistEnum  nextObject]) {
        ONOXMLElement *thumbElement = [[[playlistElement firstChildWithXPath:@".//span[contains(@class, 'yt-thumb-clip')]"] children ] firstObject];
        ONOXMLElement *playlistTitleElement = [[[playlistElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"]children ] firstObject] ;
        NSString *thumbPath = [thumbElement valueForAttribute:@"src"];
        NSString *playlistTitle = [playlistTitleElement valueForAttribute:@"title"];
        NSString *playlistURL = [[playlistTitleElement valueForAttribute:@"href"] lastPathComponent];
        // NSDictionary *playlistItem = @{@"thumbURL": thumbPath, @"title": playlistTitle, @"URL": playlistURL};
        KBYTSearchResult *result = [KBYTSearchResult new];
        //DLog(@"thumbPath: %@", thumbPath);
        if ([thumbPath rangeOfString:@"&w=246&h=138&"].location != NSNotFound)
        {
            thumbPath = [thumbPath stringByReplacingOccurrencesOfString:@"&w=246&h=138&" withString:@"&w=640&h=480&"];
        }
        if ([thumbPath containsString:@"https"])
        {
            result.imagePath = thumbPath;
        } else {
            result.imagePath = [NSString stringWithFormat:@"https:%@", thumbPath];
        }
        
        result.title = playlistTitle;
        result.author = userName;
        result.videoId = playlistURL;
        result.resultType =kYTSearchResultTypeChannel;
        //NSDictionary *playlistItem = @{@"thumbURL": [NSString stringWithFormat:@"https:%@", thumbPath], @"title": playlistTitle, @"URL": playlistURL, @"videoCount": videoCount};
        [finalArray addObject:result];
        //[finalArray addObject:playlistItem];
        
    }
    return finalArray;
}

- (NSArray *)channelArrayFromUserName:(NSString *)userName {
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/%@/channels?view=56&shelf_id=0", userName]];
    ONOXMLElement *root = [xmlDoct rootElement];
    // NSLog(@"root: %@", root);
    ONOXMLElement *playlistGroup = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    id playlistEnum = [playlistGroup XPath:@".//li[contains(@class, 'channels-content-item')]"];
    ONOXMLElement *playlistElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    while (playlistElement = [playlistEnum  nextObject]) {
        ONOXMLElement *thumbElement = [[[playlistElement firstChildWithXPath:@".//span[contains(@class, 'yt-thumb-clip')]"] children ] firstObject];
        ONOXMLElement *playlistTitleElement = [[[playlistElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"]children ] firstObject] ;
        NSString *thumbPath = [thumbElement valueForAttribute:@"src"];
        NSString *playlistTitle = [playlistTitleElement valueForAttribute:@"title"];
        NSString *playlistURL = [[playlistTitleElement valueForAttribute:@"href"] lastPathComponent];
       // NSDictionary *playlistItem = @{@"thumbURL": thumbPath, @"title": playlistTitle, @"URL": playlistURL};
        KBYTSearchResult *result = [KBYTSearchResult new];
        //DLog(@"thumbPath: %@", thumbPath);
        if ([thumbPath rangeOfString:@"&w=246&h=138&"].location != NSNotFound)
        {
            thumbPath = [thumbPath stringByReplacingOccurrencesOfString:@"&w=246&h=138&" withString:@"&w=640&h=480&"];
        }
        if ([thumbPath containsString:@"https"])
        {
            result.imagePath = thumbPath;
        } else {
            result.imagePath = [NSString stringWithFormat:@"https:%@", thumbPath];
        }
        
        result.title = playlistTitle;
        result.author = userName;
        result.videoId = playlistURL;
        result.resultType =kYTSearchResultTypeChannel;
        //NSDictionary *playlistItem = @{@"thumbURL": [NSString stringWithFormat:@"https:%@", thumbPath], @"title": playlistTitle, @"URL": playlistURL, @"videoCount": videoCount};
        [finalArray addObject:result];
        //[finalArray addObject:playlistItem];
        
    }
    return finalArray;
}


- (void)getUserVideos:(NSString *)channelID
          completionBlock:(void(^)(NSDictionary *searchDetails))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/user/%@/videos", channelID];
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
            ONOXMLElement *root = [xmlDoc rootElement];
            //NSLog(@"root element: %@", root);
            ONOXMLElement *headerSection = [root firstChildWithXPath:@"//div[contains(@id, 'gh-banner')]"];
            NSString *headerString = [[[headerSection children] firstObject] stringValue];
            // DLog(@"headerString: %@", headerString);
            NSScanner *bannerScanner = [NSScanner scannerWithString:headerString];
            NSString *headerBanner = nil;
            [bannerScanner scanUpToString:@");" intoString:&headerBanner];
            headerBanner = [[headerBanner componentsSeparatedByString:@"//"] lastObject];
            if (headerBanner != nil){
                headerBanner = [@"https://" stringByAppendingString:headerBanner];
            }
            ONOXMLElement *videosElement = [root firstChildWithXPath:@"//*[contains(@class, 'channels-browse-content-grid')]"];
            id videoEnum = [videosElement XPath:@"//div[contains(@class, 'yt-lockup-video')]"];
            ONOXMLElement *currentElement = nil;
            NSMutableArray *finalArray = [NSMutableArray new];
            NSMutableDictionary *outputDict = [NSMutableDictionary new];
            ONOXMLElement *channelNameElement = [root firstChildWithXPath:@"//meta[contains(@name, 'title')]"];
            ONOXMLElement *channelDescElement = [root firstChildWithXPath:@"//meta[contains(@name, 'description')]"];
            
            //<span class="yt-subscription-button-subscriber-count-branded-horizontal subscribed yt-uix-tooltip" title="10,323,793" tabindex="0" aria-label="10,323,793 subscribers" data-tooltip-text="10,323,793" aria-labelledby="yt-uix-tooltip88-arialabel">10,323,793</span>
            
            ONOXMLElement *channelSubscribersElement = [root firstChildWithXPath:@"//span[contains(@class, 'yt-subscription-button-subscriber-count-branded-horizontal')]"];
            
            ONOXMLElement *channelKeywordsElement = [root firstChildWithXPath:@"//meta[contains(@name, 'keywords')]"];
            ONOXMLElement *channelThumbNailElement = [[[root firstChildWithXPath:@".//*[contains(@class, 'channel-header-profile-image-container')]"] children] firstObject];
            
            
            NSString *headerThumb = nil;
            
            if (channelThumbNailElement != nil)
            {
                headerThumb = [channelThumbNailElement valueForAttribute:@"src"];
                if (![headerThumb containsString:@"https"])
                {
                    outputDict[@"thumbnail"] = [@"https:" stringByAppendingString:headerThumb];
                    
                    //NSLog(@"hop  %@", headerThumb);
                } else {
                    
                    outputDict[@"thumbnail"] = headerThumb;
                    
                }
            }
            
           
            ONOXMLElement *canon = [root firstChildWithXPath:@"//link[contains(@rel, 'canonical')]"];
             DLog(@"canon: %@", canon);
            outputDict[@"channelID"] = [[canon valueForAttribute:@"href"] lastPathComponent];
            
            if (channelSubscribersElement != nil)
            {
                outputDict[@"subscribers"] = [channelSubscribersElement valueForAttribute:@"aria-label"];
            }
            
            if (channelNameElement != nil)
            {
                outputDict[@"name"] = [channelNameElement valueForAttribute:@"content"];
            }
            if (channelDescElement != nil)
            {
                outputDict[@"description"] = [channelDescElement valueForAttribute:@"content"];
            }
            if (channelKeywordsElement != nil)
            {
                outputDict[@"keywords"] = [channelKeywordsElement valueForAttribute:@"content"];
            }
            if (headerBanner != nil)
            {
                outputDict[@"banner"] = headerBanner;
            }
            while (currentElement = [videoEnum nextObject])
            {
                //NSMutableDictionary *scienceDict = [NSMutableDictionary new];
                KBYTSearchResult *result = [KBYTSearchResult new];
                NSString *videoID = [currentElement valueForAttribute:@"data-context-item-id"];
                if (videoID != nil)
                {
                    result.videoId = videoID;
                }
                ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-clip')]"] children] firstObject];
                ONOXMLElement *lengthElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
                ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"];
                ;
                ONOXMLElement *descElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-description')]"];
                ONOXMLElement *authorElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-byline')]"] children] firstObject];
                ONOXMLElement *ageAndViewsElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-meta-info')]"];//yt-lockup-meta-info
                NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                if (imagePath == nil)
                {
                    imagePath = [thumbNailElement valueForAttribute:@"src"];
                }
                //w=196&h=110
                if (imagePath != nil)
                {
                    
                    imagePath = [self attemptConvertImagePathToHiRes:imagePath];
                    
                    
                    if ([imagePath containsString:@"https:"])
                    {
                        result.imagePath = imagePath;
                    } else {
                        result.imagePath = [@"https:" stringByAppendingString:imagePath];
                    }
                }
                
                result.resultType =kYTSearchResultTypeVideo;
                
                if (lengthElement != nil)
                    result.duration = lengthElement.stringValue;
                
                if (titleElement != nil)
                {
                    result.title = [[[titleElement children]firstObject] valueForAttribute:@"title"];
                }
                
                NSString *vdesc = [[descElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                if (vdesc != nil)
                {
                    result.details = [vdesc stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
                
                if (authorElement != nil)
                {
                    result.author = [authorElement stringValue];
                }
                for (ONOXMLElement *currentElement in [ageAndViewsElement children])
                {
                    NSString *currentValue = [currentElement stringValue];
                    if ([currentValue containsString:@"ago"]) //age
                    {
                        result.age = currentValue;
                    } else if ([currentValue containsString:@"views"])
                    {
                        result.views = [[currentValue componentsSeparatedByString:@" "] firstObject];
                    }
                }
                
                if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
                {
                    //NSLog(@"result: %@", result);
                    [finalArray addObject:result];
                } else {
                    result = nil;
                }
                
            }
            if (outputDict[@"name"] != nil)
            {
                NSArray *channelPlaylists = [self playlistArrayFromUserName:outputDict[@"name"]];
                outputDict[@"playlists"] = channelPlaylists;
                
            }
            if ([finalArray count] > 0)
            {
                ONOXMLElement *loadMoreButton = [root firstChildWithXPath:@"//button[contains(@class, 'load-more-button')]"];
                NSString *loadMoreHREF = [loadMoreButton valueForAttribute:@"data-uix-load-more-href"];
                if (loadMoreHREF != nil){
                    outputDict[@"loadMoreREF"] = loadMoreHREF;
                }
                outputDict[@"results"] = finalArray;
                outputDict[@"resultCount"] = [NSNumber numberWithInteger:[finalArray count]];
                NSInteger pageCount = 1;
                outputDict[@"pageCount"] = [NSNumber numberWithInteger:pageCount];
            }
            NSString *errorString = @"failed to get featured details";
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([finalArray count] > 0)
                {
                    completionBlock(outputDict);
                } else {
                    failureBlock(errorString);
                }
            });
        }
    });
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
    }
    NSString *vid = [current recursiveObjectForKey:@"videoId"];//current[@"videoId"];
    NSString *viewCountText = current[@"viewCountText"][@"simpleText"];
    NSArray *thumbnails = current[@"thumbnail"][@"thumbnails"] ? current[@"thumbnail"][@"thumbnails"] : [current recursiveObjectForKey:@"thumbnail"][@"thumbnails"];
    //https://i.ytimg.com/vi/VIDEO_ID/hqdefault.jpg
    NSDictionary *thumb = thumbnails.lastObject;
    NSString *imagePath = thumb[@"url"];
    NSInteger width = [thumb[@"width"] integerValue];
    if (width < 300){
        imagePath = [NSString stringWithFormat:@"https://i.ytimg.com/vi/%@/hqdefault.jpg", vid];
    }
    NSDictionary *longBylineText = [current recursiveObjectForKey:@"longBylineText"];
    if (!longBylineText) {
        longBylineText = [current recursiveObjectForKey:@"shortBylineText"];
    }
    NSDictionary *ownerText = current[@"ownerText"];
    if (!ownerText) {
        ownerText = longBylineText;
    }
    //current[@"publishedTimeText"][@"simpleText"];
    KBYTSearchResult *searchItem = [KBYTSearchResult new];
    searchItem.details = [longBylineText recursiveObjectForKey:@"text"];
    searchItem.author = [ownerText recursiveObjectForKey:@"text"];
    searchItem.title = fullTitle;
    searchItem.duration = lengthText;
    searchItem.videoId = vid;
    searchItem.views = viewCountText;
    searchItem.age = current[@"publishedTimeText"][@"simpleText"];
    searchItem.imagePath = imagePath;
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
        
        @autoreleasepool {
            NSString *url = [self browseURL];
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForChannelID:channelID continuation:continuationToken];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            //NSLog(@"[tuyu] params: %@", params);
            //NSLog(@"body: %@ for: %@ %@", jsonDict, url, params);
            //NSMutableArray* arr = [NSMutableArray array];
            //[self obtainKeyPaths:jsonDict intoArray:arr withString:nil];
            //NSLog(@"[tuyu] file: %@", [NSHomeDirectory() stringByAppendingPathComponent:@"channelAlt.plist"]);
            
            [jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"sports.plist"] atomically:true];
            
            NSArray *banner = [jsonDict recursiveObjectForKey:@"banner"][@"thumbnails"];
            NSString *lastBanner = [banner lastObject][@"url"];
            //NSLog(@"our banners: %@", lastBanner);
            id cc = [jsonDict recursiveObjectForKey:@"continuationCommand"];
            
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
            NSInteger width = [thumb[@"height"] integerValue];
            NSString *imagePath = thumb[@"url"];
            
            if (width < 400){
                NSLog(@"generate thumb manually!");
                imagePath = [self hiRestChannelImageFromDict:thumb];
            }
            if (![imagePath containsString:@"https:"]){
                imagePath = [NSString stringWithFormat:@"https:%@", imagePath];
            }
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
            channel.subscribers = subscriberCount[@"simpleText"];
            channel.image = imagePath;
            channel.url = [details recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"canonicalBaseUrl"];
            channel.continuationToken = cc[@"token"];
            channel.banner = lastBanner;
            //DLog(@"details: %@", details);
            //title,subtitle,thumbnails
            //[jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"music.plist"] atomically:true];
            NSArray *sect = [jsonDict recursiveObjectsLikeKey:@"itemSectionRenderer"];
            if (sect.count == 0) {
                NSDictionary *richGridRenderer = [jsonDict recursiveObjectLikeKey:@"richGridRenderer"];
                sect = richGridRenderer[@"contents"];
                //NSLog(@"[tuyu] no content for some retarded reason");
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
                        //NSLog(@"[tuyu] no videoRenderer!: %@", obj);
                        id cc = [obj recursiveObjectForKey:@"continuationCommand"];
                        //NSLog(@"[tuyu] cc: %@", cc);
                        channel.continuationToken = cc[@"token"];
                        NSDictionary *channelRender = [obj recursiveObjectForKey:@"channelVideoPlayerRenderer"];
                        if (channelRender){
                            NSLog(@"[tuyu] channel renderer found: %@", [channelRender allKeys]);
                        }
                        
                    }
                    //NSLog(@"[tuyu] idx: %lu of %lu", idx, [sect count]);
                    if (idx+1 == sect.count && backup){
                        //NSLog(@"[tuyu] adding straggler!");
                        [sections addObject:backup];
                        backup = nil;
                    }
                } else {
                    if (backup) {
                        [sections addObject:backup];
                        backup = nil;
                    }
                    //NSDictionary *rend = [renderers firstObject];
                    NSDictionary *title = [shelf recursiveObjectForKey:@"title"];
                    KBYTSection *section = [KBYTSection new];
                    section.title = title[@"simpleText"] ? title[@"simpleText"] : [title recursiveObjectForKey:@"text"];
                    NSLog(@"idx %lu shelf: %@", idx, section.title);
                    
                    NSArray *videos = [shelf recursiveObjectsLikeKey:@"videoRenderer"];
                    //NSLog(@"videos: %@", videos);
                    __block NSMutableArray *content = [NSMutableArray new];
                    if (videos){
                        NSLog(@"videos: %lu", videos.count);
                        [videos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSString *first = [[obj allKeys] firstObject];
                            NSDictionary *vid = obj[first];
                            if (vid){
                                KBYTSearchResult *video = [self searchResultFromVideoRenderer:vid];
                                //NSLog(@"video: %@", video);
                                [content addObject:video];
                            }
                        }];
                    } else {
                        NSArray *stations = [shelf recursiveObjectsLikeKey:@"stationRenderer"];
                        if (stations.count > 0){
                            NSLog(@"stations: %lu", stations.count);
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
                                searchItem.imagePath = last;
                                searchItem.author = channel.title;
                                searchItem.resultType = kYTSearchResultTypePlaylist;
                                searchItem.details = [desc recursiveObjectForKey:@"simpleText"];
                                //NSLog(@"searchItem: %@", searchItem);
                                [content addObject:searchItem];
                            }];
                        } else {
                            
                            NSArray *stations = [shelf recursiveObjectsLikeKey:@"playlistRenderer"];
                            if (stations.count > 0){
                                
                                NSLog(@"playlists count: %lu", stations.count);
                                [stations enumerateObjectsUsingBlock:^(id  _Nonnull station, NSUInteger idx, BOOL * _Nonnull stop) {
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
                                    searchItem.age = playlist[@"publishedTimeText"][@"simpleText"];
                                    searchItem.author = channel.title;
                                    searchItem.resultType = kYTSearchResultTypePlaylist;
                                    searchItem.details = [desc recursiveObjectForKey:@"simpleText"];
                                    [content addObject:searchItem];
                                }];
                                
                            } else {
                                stations = [shelf recursiveObjectsLikeKey:@"channelRenderer"];
                                if (stations.count > 0){
                                    NSLog(@"channels count: %lu", stations.count);
                                    [stations enumerateObjectsUsingBlock:^(id  _Nonnull channelObj, NSUInteger idx, BOOL * _Nonnull stop) {
                                        NSString *firstKey = [[channelObj allKeys] firstObject];
                                        NSDictionary *channel = channelObj[firstKey];
                                        
                                        NSDictionary *title = channel[@"title"];//[channel recursiveObjectForKey:@"title"];
                                        NSString *cis = channel[@"channelId"];
                                        NSArray *thumbnails = channel[@"thumbnail"][@"thumbnails"];
                                        NSDictionary *longBylineText = channel[@"longBylineText"];
                                        NSDictionary *thumb = thumbnails.lastObject;
                                        NSString *imagePath = thumb[@"url"];
                                        NSInteger width = [thumb[@"height"] integerValue];
                                        if (width < 400){
                                            NSLog(@"generate thumb manually!");
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
                                        searchItem.imagePath = imagePath;
                                        searchItem.resultType = kYTSearchResultTypeChannel;
                                        searchItem.details = [channel recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"canonicalBaseUrl"];
                                        NSLog(@"channel: %@ keys: %@", searchItem, channel.allKeys);
                                        [content addObject:searchItem];
                                    }];
                                    
                                } else { //shorts maybe?
                                    //NSLog(@"rend: %@", rend);
                                    stations = [shelf recursiveObjectsLikeKey:@"reelItemRenderer"];
                                    NSLog(@"reels: %lu", stations.count);
                                    if (stations.count == 0){
                                        NSLog(@"rend: %@", shelf);
                                    }
                                    [stations enumerateObjectsUsingBlock:^(id  _Nonnull reel, NSUInteger idx, BOOL * _Nonnull stop) {
                                        NSString *firstKey = [[reel allKeys] firstObject];
                                        NSDictionary *reelObject = reel[firstKey];
                                        NSArray *thumbnails = [reelObject recursiveObjectForKey:@"thumbnail"][@"thumbnails"];
                                        NSString *last = thumbnails.lastObject[@"url"];
                                        //NSLog(@"keys: %@", [reelObject allKeys]);
                                        KBYTSearchResult *searchItem = [KBYTSearchResult new];
                                        searchItem.title = reelObject[@"headline"][@"simpleText"];
                                        searchItem.videoId = reelObject[@"videoId"];
                                        searchItem.views = reelObject[@"viewCountText"][@"simpleText"];
                                        searchItem.resultType = kYTSearchResultTypeVideo;
                                        searchItem.imagePath = last;
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
                    [sections addObject:section];
                }
                
                
            }];
            NSLog(@"sections: %@", sections);
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
            if (completionBlock) {
                completionBlock(channel);
            }
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
                //NSLog(@"[tuyu] got playlist: %@", playlist);
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


- (void)getOrganizedChannelData:(NSString *)channelID
                       completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
                          failureBlock:(void(^)(NSString* error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/channel/%@", channelID];
           
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
            ONOXMLElement *root = [xmlDoc rootElement];
            
            //START NEW STUFFZ
            
            ONOXMLElement *headerSection = [root firstChildWithXPath:@"//div[contains(@id, 'gh-banner')]"];
            NSString *headerString = [[[headerSection children] firstObject] stringValue];
            // DLog(@"headerString: %@", headerString);
            NSScanner *bannerScanner = [NSScanner scannerWithString:headerString];
            NSString *headerBanner = nil;
            [bannerScanner scanUpToString:@");" intoString:&headerBanner];
            headerBanner = [[headerBanner componentsSeparatedByString:@"//"] lastObject];
            if (headerBanner != nil){
                headerBanner = [@"https://" stringByAppendingString:headerBanner];
            }
            NSMutableDictionary *finalDict = [NSMutableDictionary new];
            NSMutableArray *sections = [NSMutableArray new];
            ONOXMLElement *channelNameElement = [root firstChildWithXPath:@"//meta[contains(@name, 'title')]"];
            ONOXMLElement *channelDescElement = [root firstChildWithXPath:@"//meta[contains(@name, 'description')]"];
            
            //<span class="yt-subscription-button-subscriber-count-branded-horizontal subscribed yt-uix-tooltip" title="10,323,793" tabindex="0" aria-label="10,323,793 subscribers" data-tooltip-text="10,323,793" aria-labelledby="yt-uix-tooltip88-arialabel">10,323,793</span>
            
            ONOXMLElement *channelSubscribersElement = [root firstChildWithXPath:@"//span[contains(@class, 'yt-subscription-button-subscriber-count-branded-horizontal')]"];
            
            ONOXMLElement *channelKeywordsElement = [root firstChildWithXPath:@"//meta[contains(@name, 'keywords')]"];
            ONOXMLElement *channelThumbNailElement = [[[root firstChildWithXPath:@".//*[contains(@class, 'channel-header-profile-image-container')]"] children] firstObject];
            
            
            NSString *headerThumb = nil;
            
            if (channelThumbNailElement != nil)
            {
                headerThumb = [channelThumbNailElement valueForAttribute:@"src"];
                if (![headerThumb containsString:@"https"])
                {
                    finalDict[@"thumbnail"] = [@"https:" stringByAppendingString:headerThumb];
                    
                    //NSLog(@"hop  %@", headerThumb);
                } else {
                    
                    finalDict[@"thumbnail"] = headerThumb;
                    
                }
            }
            
            finalDict[@"channelID"] = channelID;
            
            if (channelSubscribersElement != nil)
            {
                finalDict[@"subscribers"] = [channelSubscribersElement valueForAttribute:@"aria-label"];
            }
            
            if (channelNameElement != nil)
            {
                finalDict[@"name"] = [channelNameElement valueForAttribute:@"content"];
            }
            if (channelDescElement != nil)
            {
                finalDict[@"description"] = [channelDescElement valueForAttribute:@"content"];
            }
            if (channelKeywordsElement != nil)
            {
                finalDict[@"keywords"] = [channelKeywordsElement valueForAttribute:@"content"];
            }
            if (headerBanner != nil)
            {
                finalDict[@"banner"] = headerBanner;
            }
            
            
            
            
            //END NEW STUFFZ
            
            //NSLog(@"root element: %@", root);
            //NSString *XPath = @"//ol[contains(@class, 'section-list')]";
            ONOXMLElement *sectionListElement = root;
            ONOXMLElement *numListElement = [sectionListElement firstChildWithXPath:@"//p[contains(@class,'num-results')]"];
            NSInteger results = 0;
            if (numListElement !=nil)
            {
                NSString *resultText = [numListElement stringValue];
                results = [[[[[resultText componentsSeparatedByString:@"About"] lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""] integerValue];
            }
            
            id sectionEnum = [sectionListElement XPath:@"//li[contains(@class, 'feed-item-container')]"];
            
            ONOXMLElement *videosElement = nil;
            //  NSMutableArray *videoArray = [NSMutableArray new];
            while (videosElement = [sectionEnum nextObject])
            {
                NSMutableDictionary *channelDict = [NSMutableDictionary new];
                // ONOXMLElement *videosElement = [sectionListElement firstChildWithXPath:@"//ol[contains(@class, 'item-section')]"];
                //<span class="branded-page-module-title-text">Newsbud</span>
                NSString *sectionTitleXPath = @".//span[contains(@class, 'branded-page-module-title-text')]";
                ONOXMLElement *sectionNameElement = [videosElement firstChildWithXPath:sectionTitleXPath];
                NSString *channelName = [sectionNameElement stringValue];
                if (channelName != nil)
                {
                    channelName = [channelName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    channelDict[@"name"] = channelName;
                }
                ONOXMLElement *itemHrefForSection = [videosElement firstChildWithXPath:@".//h2[contains(@class, 'branded-page-module-title shelf-title-cell')]"];
                if (itemHrefForSection.children.count > 0)
                {
                    ONOXMLElement *firstChild = [[itemHrefForSection children] firstObject];
                    NSString *url = [firstChild valueForAttribute:@"href"];
                    
                    ONOXMLElement *channelPic = [firstChild firstChildWithXPath:@"//span[contains(@class, 'yt-thumb-simple')]"];
                    ONOXMLElement *picChild = [[channelPic children] firstObject];
                    NSString *imageUrl = [picChild valueForAttribute:@"src"];
                    if (url.length > 0)
                    {
                        channelDict[@"url"] = url;
                    }
                    if (imageUrl.length > 0)
                    {
                        channelDict[@"imageUrl"] = imageUrl;
                    }
                    //DLog(@"channel %@ url: %@ image: %@", channelName, url, imageUrl);
                    
                    
                }
                id videoEnum = [videosElement XPath:@".//div[contains(@class, 'yt-lockup-video')]"];
                ONOXMLElement *currentElement = nil;
                NSMutableArray *finalArray = [NSMutableArray new];
                if ([[videoEnum allObjects] count] == 0) //top shelf most likely
                {
                    
                    //NSMutableDictionary *scienceDict = [NSMutableDictionary new];
                    KBYTSearchResult *result = [KBYTSearchResult new];
                    
                    ONOXMLElement *fullTopShelf = [videosElement firstChildWithXPath:@".//div[contains(@class, 'lohp-shelf-content')]"];
                    currentElement = [[fullTopShelf children] firstObject];
                    
                    ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//a[contains(@class, 'lohp-video-link')]"];
                    NSString *videoID = [titleElement valueForAttribute:@"href"];
                    if (videoID != nil)
                    {
                        result.videoId = [[videoID componentsSeparatedByString:@"="] lastObject];
                    }
                    result.resultType =kYTSearchResultTypeVideo;
                    ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-clip')]"] children] firstObject];
                    ONOXMLElement *lengthElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
                    ONOXMLElement *ageAndViewsElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'lohp-video-metadata')]"];//yt-lockup-meta-info
                    ONOXMLElement *authorElement = [[[ageAndViewsElement firstChildWithXPath:@".//*[contains(@class, 'content-uploader')]"] children] lastObject];
                    
                    NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                    if (imagePath == nil)
                    {
                        imagePath = [thumbNailElement valueForAttribute:@"src"];
                    }
                    
                    if (imagePath != nil)
                    {
                        imagePath = [self attemptConvertImagePathToHiRes:imagePath];
                        
                        
                        if ([imagePath containsString:@"https:"])
                        {
                            result.imagePath = imagePath;
                        } else {
                            result.imagePath = [@"https:" stringByAppendingString:imagePath];
                        }
                        
                    }
                    if (lengthElement != nil)
                        result.duration = lengthElement.stringValue;
                    
                    if (titleElement != nil)
                        result.title = [[titleElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    
                    if (authorElement != nil)
                    {
                        result.author = [authorElement stringValue];
                    }
                    for (ONOXMLElement *currentElement in [ageAndViewsElement children])
                    {
                        NSString *currentValue = [[currentElement stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if ([currentValue containsString:@"ago"]) //age
                        {
                            result.age = currentValue;
                        } else if ([currentValue containsString:@"views"])
                        {
                            result.views = [[currentValue componentsSeparatedByString:@" "] firstObject];
                        }
                    }
                    
                    if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
                    {
                        //NSLog(@"result: %@", result);
                        [finalArray addObject:result];
                    } else {
                        result = nil;
                    }
                    
                    //middle shelf now
                    
                    ONOXMLElement *middleShelf = [[fullTopShelf children] lastObject];
                    //lohp-medium-shelf spf-link
                    id middleEnum = [middleShelf XPath:@".//div[contains(@class, 'lohp-medium-shelf vve-check  spf-link')]"];
                    while (currentElement = [middleEnum nextObject])
                    {
                        KBYTSearchResult *result = [KBYTSearchResult new];
                        ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//a[contains(@class, 'lohp-video-link')]"];
                        NSString *videoID = [titleElement valueForAttribute:@"href"];
                        if (videoID != nil)
                        {
                            result.videoId = [[videoID componentsSeparatedByString:@"="] lastObject];
                        }
                        result.resultType =kYTSearchResultTypeVideo;
                        ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-clip')]"] children] firstObject];
                        ONOXMLElement *lengthElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
                        id ageEnum = [currentElement XPath:@".//*[contains(@class, 'lohp-video-metadata')]"];
                        
                        ONOXMLElement *ageAndViewsElement = [[ageEnum allObjects] lastObject];
                        
                        //ONOXMLElement *ageAndViewsElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'lohp-video-metadata')]"];//yt-lockup-meta-info
                        ONOXMLElement *authorElement = [[[ageAndViewsElement firstChildWithXPath:@".//*[contains(@class, 'content-uploader')]"] children] lastObject];
                        
                        NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                        if (imagePath == nil)
                        {
                            imagePath = [thumbNailElement valueForAttribute:@"src"];
                        }
                        
                        if (imagePath != nil)
                        {
                            imagePath = [self attemptConvertImagePathToHiRes:imagePath];
                            
                            
                            if ([imagePath containsString:@"https:"])
                            {
                                result.imagePath = imagePath;
                            } else {
                                result.imagePath = [@"https:" stringByAppendingString:imagePath];
                            }
                            
                        }
                        if (lengthElement != nil)
                            result.duration = lengthElement.stringValue;
                        
                        if (titleElement != nil)
                            result.title = [[titleElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        
                        if (authorElement != nil)
                        {
                            result.author = [authorElement stringValue];
                        }
                        for (ONOXMLElement *currentElement in [ageAndViewsElement children])
                        {
                            NSString *currentValue = [[currentElement stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            if ([currentValue containsString:@"ago"]) //age
                            {
                                result.age = currentValue;
                            } else if ([currentValue containsString:@"views"])
                            {
                                result.views = [[currentValue componentsSeparatedByString:@" "] firstObject];
                            }
                        }
                        
                        if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
                        {
                            //NSLog(@"result: %@", result);
                            [finalArray addObject:result];
                        } else {
                            result = nil;
                        }
                    }
                    
                    if (finalArray.count > 0){
                        channelDict[@"videos"] = finalArray;
                        finalDict[channelName] = channelDict;
                        [sections addObject:channelName];
                    }
                    
                } else {
                    while (currentElement = [videoEnum nextObject])
                    {
                        //NSMutableDictionary *scienceDict = [NSMutableDictionary new];
                        KBYTSearchResult *result = [KBYTSearchResult new];
                        NSString *videoID = [currentElement valueForAttribute:@"data-context-item-id"];
                        if (videoID != nil)
                        {
                            result.videoId = videoID;
                        }
                        result.resultType =kYTSearchResultTypeVideo;
                        ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-clip')]"] children] firstObject];
                        ONOXMLElement *lengthElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
                        ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"];
                        ;
                        ONOXMLElement *descElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-description')]"];
                        ONOXMLElement *authorElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-byline')]"] children] firstObject];
                        ONOXMLElement *ageAndViewsElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-meta-info')]"];//yt-lockup-meta-info
                        NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                        if (imagePath == nil)
                        {
                            imagePath = [thumbNailElement valueForAttribute:@"src"];
                        }
                        
                        if (imagePath != nil)
                        {
                            imagePath = [self attemptConvertImagePathToHiRes:imagePath];
                            
                            
                            if ([imagePath containsString:@"https:"])
                            {
                                result.imagePath = imagePath;
                            } else {
                                result.imagePath = [@"https:" stringByAppendingString:imagePath];
                            }
                            
                        }
                        if (lengthElement != nil)
                            result.duration = lengthElement.stringValue;
                        
                        if (titleElement != nil)
                            result.title = [[titleElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        
                        NSString *vdesc = [[descElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        if (vdesc != nil)
                        {
                            result.details = [vdesc stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        }
                        
                        if (authorElement != nil)
                        {
                            result.author = [authorElement stringValue];
                        }
                        for (ONOXMLElement *currentElement in [ageAndViewsElement children])
                        {
                            NSString *currentValue = [currentElement stringValue];
                            if ([currentValue containsString:@"ago"]) //age
                            {
                                result.age = currentValue;
                            } else if ([currentValue containsString:@"views"])
                            {
                                result.views = [[currentValue componentsSeparatedByString:@" "] firstObject];
                            }
                        }
                        
                        if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
                        {
                            //NSLog(@"result: %@", result);
                            [finalArray addObject:result];
                        } else {
                            result = nil;
                        }
                        
                        
                    }
                    
                    if (finalArray.count > 0){
                        channelDict[@"videos"] = finalArray;
                        finalDict[channelName] = channelDict;
                        [sections addObject:channelName];
                    }
                    
                }
                //NSMutableDictionary *outputDict = [NSMutableDictionary new];

            }
            
            
            
            if ([finalDict.allKeys count] > 0)
            {
                finalDict[@"sections"] = sections;
                
                ONOXMLElement *loadMoreButton = [root firstChildWithXPath:@"//button[contains(@class, 'load-more-button')]"];
                NSString *loadMoreHREF = [loadMoreButton valueForAttribute:@"data-uix-load-more-href"];
                if (loadMoreHREF != nil){
                    finalDict[@"loadMoreREF"] = loadMoreHREF;
                }
                // finalDict[@"results"] = finalArray;
                NSInteger pageCount = 1;
                //finalDict[@"resultCount"] = [NSNumber numberWithInteger:[finalArray count]];
                
                //finalDict[@"pageCount"] = [NSNumber numberWithInteger:pageCount];
            }
            
            NSString *errorString = @"failed to get featured details";
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([finalDict.allKeys count] > 0)
                {
                    completionBlock(finalDict);
                } else {
                    failureBlock(errorString);
                }
            });
        }
    });
    
}

- (void)getFeaturedVideosWithCompletionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
                                failureBlock:(void(^)(NSString* error))failureBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            NSString *requestString = @"https://m.youtube.com/";
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
            ONOXMLElement *root = [xmlDoc rootElement];
            //NSLog(@"root element: %@", root);
            NSString *XPath = @"//ol[contains(@class, 'section-list')]";
            ONOXMLElement *sectionListElement = [root firstChildWithXPath:XPath];
            ONOXMLElement *numListElement = [sectionListElement firstChildWithXPath:@"//p[contains(@class,'num-results')]"];
            NSInteger results = 0;
            if (numListElement !=nil)
            {
                NSString *resultText = [numListElement stringValue];
                results = [[[[[resultText componentsSeparatedByString:@"About"] lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""] integerValue];
            }
            ONOXMLElement *videosElement = [sectionListElement firstChildWithXPath:@"//ol[contains(@class, 'item-section')]"];
            //<span class="branded-page-module-title-text">Newsbud</span>
            NSString *sectionTitleXPath = @"//span[contains(@class, 'branded-page-module-title-text')]";
            ONOXMLElement *sectionNameElement = [videosElement firstChildWithXPath:sectionTitleXPath];
            NSString *channelName = [sectionNameElement stringValue];
            
            ONOXMLElement *itemHrefForSection = [videosElement firstChildWithXPath:@"//h2[contains(@class, 'branded-page-module-title shelf-title-cell')]"];
            if (itemHrefForSection.children.count > 0)
            {
                ONOXMLElement *firstChild = [[itemHrefForSection children] firstObject];
                NSString *url = [firstChild valueForAttribute:@"href"];
                
                ONOXMLElement *channelPic = [firstChild firstChildWithXPath:@"//span[contains(@class, 'yt-thumb-simple')]"];
                ONOXMLElement *picChild = [[channelPic children] firstObject];
                NSString *imageUrl = [picChild valueForAttribute:@"src"];
                
                //DLog(@"channel %@ url: %@ image: %@", channelName, url, imageUrl);
                
                //<span class="yt-thumb-simple">
              //  <img width="20" height="20" alt="" data-ytimg="1" onload=";__ytRIL(this)" src="https://yt3.ggpht.com/-wjHl6UrTTUc/AAAAAAAAAAI/AAAAAAAAAAA/vmZp7Y91DK8/s88-c-k-no-mo-rj-c0xffffff/photo.jpg">
               // </span>
                
            }
            id videoEnum = [videosElement XPath:@"//div[contains(@class, 'yt-lockup-video')]"];
            ONOXMLElement *currentElement = nil;
            NSMutableArray *finalArray = [NSMutableArray new];
            NSMutableDictionary *outputDict = [NSMutableDictionary new];
            while (currentElement = [videoEnum nextObject])
            {
                //NSMutableDictionary *scienceDict = [NSMutableDictionary new];
                KBYTSearchResult *result = [KBYTSearchResult new];
                NSString *videoID = [currentElement valueForAttribute:@"data-context-item-id"];
                if (videoID != nil)
                {
                    result.videoId = videoID;
                }
                result.resultType =kYTSearchResultTypeVideo;
                ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-simple')]"] children] firstObject];
                ONOXMLElement *lengthElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
                ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-title')]"];
                ;
                ONOXMLElement *descElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-description')]"];
                ONOXMLElement *authorElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-byline')]"] children] firstObject];
                ONOXMLElement *ageAndViewsElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-meta-info')]"];//yt-lockup-meta-info
                NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                if (imagePath == nil)
                {
                    imagePath = [thumbNailElement valueForAttribute:@"src"];
                }
                
                if (imagePath != nil)
                {
                    imagePath = [self attemptConvertImagePathToHiRes:imagePath];
                    
                    
                    if ([imagePath containsString:@"https:"])
                    {
                        result.imagePath = imagePath;
                    } else {
                        result.imagePath = [@"https:" stringByAppendingString:imagePath];
                    }
                    
                }
                if (lengthElement != nil)
                    result.duration = lengthElement.stringValue;
                
                if (titleElement != nil)
                    result.title = [[titleElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                
                NSString *vdesc = [[descElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                if (vdesc != nil)
                {
                    result.details = [vdesc stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
                
                if (authorElement != nil)
                {
                    result.author = [authorElement stringValue];
                }
                for (ONOXMLElement *currentElement in [ageAndViewsElement children])
                {
                    NSString *currentValue = [currentElement stringValue];
                    if ([currentValue containsString:@"ago"]) //age
                    {
                        result.age = currentValue;
                    } else if ([currentValue containsString:@"views"])
                    {
                        result.views = [[currentValue componentsSeparatedByString:@" "] firstObject];
                    }
                }
                
                if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
                {
                    //NSLog(@"result: %@", result);
                    [finalArray addObject:result];
                } else {
                    result = nil;
                }
                if ([finalArray count] > 0)
                {
                    ONOXMLElement *loadMoreButton = [root firstChildWithXPath:@"//button[contains(@class, 'load-more-button')]"];
                    NSString *loadMoreHREF = [loadMoreButton valueForAttribute:@"data-uix-load-more-href"];
                    if (loadMoreHREF != nil){
                        outputDict[@"loadMoreREF"] = loadMoreHREF;
                    }
                    outputDict[@"results"] = finalArray;
                    NSInteger pageCount = 1;
                    outputDict[@"resultCount"] = [NSNumber numberWithInteger:[finalArray count]];
                    
                    outputDict[@"pageCount"] = [NSNumber numberWithInteger:pageCount];
                }
            }
            NSString *errorString = @"failed to get featured details";
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([finalArray count] > 0)
                {
                    completionBlock(outputDict);
                } else {
                    failureBlock(errorString);
                }
            });
        }
    });
    
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
            NSString *errorString = nil;
            NSString *url = [self playerURL];
            NSLog(@"url: %@", url);
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForVideo:videoID];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            //NSLog(@"body: %@ for: %@ %@", jsonDict, url, params);
            [jsonDict writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"file2.plist"] atomically:true];
            
            rootInfo = [[KBYTMedia alloc] initWithJSON:jsonDict];
            //NSLog(@"root info: %@", rootInfo);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(rootInfo != nil)
                {
                    completionBlock(rootInfo);
                } else {
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
            NSLog(@"video count: %lu", results.videos.count);
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
            NSString *errorString = nil;
            
            NSInteger i = 0;
            
            for (KBYTSearchResult *result in searchResults) {
                
                if (!result.videoId){
                    NSLog(@"[tuyu] missing video id: %@ bail!", result);
                    continue;;
                }
                
                NSString *url = [self playerURL];
                NSLog(@"url: %@", url);
                //get the post body from the url above, gets the initial raw info we work with
                NSDictionary *params = [self paramsForVideo:result.videoId];
                NSString *body = [self stringFromPostRequest:url withParams:params];
                NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
                KBYTMedia *currentMedia = [[KBYTMedia alloc] initWithJSON:jsonDict];
                [finalArray addObject:currentMedia];
                
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
            NSString *errorString = nil;
            
            //the url we use to call get_video_info
            
            NSInteger i = 0;
            
            for (NSString *videoID in videoIDs) {
                
                NSString *url = [self playerURL];
                NSLog(@"url: %@", url);
                //get the post body from the url above, gets the initial raw info we work with
                NSDictionary *params = [self paramsForVideo:videoID];
                NSString *body = [self stringFromPostRequest:url withParams:params];
                NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
                KBYTMedia *currentMedia = [[KBYTMedia alloc] initWithJSON:jsonDict];
                [finalArray addObject:currentMedia];
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
