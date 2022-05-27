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


static NSString * const hardcodedTimestamp = @"16864";
static NSString * const hardcodedCipher = @"42,0,14,-3,0,-1,0,-2";

/**
 
 out of pure laziness I put the implementation KBYTStream and KBYTMedia classes in this file and their interfaces
 in the header file. However, it does provide easier portability since I have yet to make this into a library/framework/pod
 
 
 */

@implementation KBYTChannel

- (NSString *)description {
    NSString *desc = [super description];
    return [NSString stringWithFormat:@"%@ videos: %@ title: %@ ID: %@", desc, _videos, _title, _channelID];
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

- (void)processJSON:(NSDictionary *)jsonDict {
    __block NSMutableArray *searchResults = [NSMutableArray new];
    __block NSMutableArray *playlistResults = [NSMutableArray new];
    __block NSMutableArray *channelResults = [NSMutableArray new];
    NSArray *videos = [jsonDict recursiveObjectsForKey:@"videoRenderer"];
    NSArray *playlists = [jsonDict recursiveObjectsForKey:@"playlistRenderer"];
    NSArray *channels = [jsonDict recursiveObjectsForKey:@"channelRenderer"];
    NSInteger estimatedResults = [[jsonDict recursiveObjectForKey:@"estimatedResults"] integerValue];
    //NSLog(@"playlists: %@", playlists);
    //NSLog(@"channels: %@", channels);
    if (channels){
        [channels writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"channels.plist"] atomically:true];
    }
    NSLog(@"estimated results: %lu", estimatedResults);
    id cc = [jsonDict recursiveObjectForKey:@"continuationCommand"];
    self.continuationToken = cc[@"token"];
    //NSLog(@"cc: %@", cc);
    [videos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *current = obj[@"videoRenderer"];
        if (current) {
            NSString *lengthText = current[@"lengthText"][@"simpleText"];
            NSDictionary *title = current[@"title"];
            NSString *vid = current[@"videoId"];
            NSString *viewCountText = current[@"viewCountText"][@"simpleText"];
            NSArray *thumbnails = current[@"thumbnail"][@"thumbnails"];
            NSDictionary *longBylineText = current[@"longBylineText"];
            NSDictionary *ownerText = current[@"ownerText"];
            KBYTSearchResult *searchItem = [KBYTSearchResult new];
            searchItem.details = [longBylineText recursiveObjectForKey:@"text"];
            searchItem.author = [ownerText recursiveObjectForKey:@"text"];
            searchItem.title = [title recursiveObjectForKey:@"text"];
            searchItem.duration = lengthText;
            searchItem.videoId = vid;
            searchItem.views = viewCountText;
            searchItem.resultType = YTSearchResultTypeVideo;
            searchItem.age = current[@"publishedTimeText"][@"simpleText"];
            searchItem.imagePath = thumbnails.lastObject[@"url"];
            [searchResults addObject:searchItem];
        }
    }];
    self.videos = searchResults;
    [playlists enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *current = obj[@"playlistRenderer"];
        NSDictionary *title = [current recursiveObjectForKey:@"title"];
        NSString *pis = current[@"playlistId"];
        NSArray *thumbnails = current[@"thumbnail"][@"thumbnails"];
        NSDictionary *longBylineText = current[@"longBylineText"];
        KBYTSearchResult *searchItem = [KBYTSearchResult new];
        searchItem.author = [longBylineText recursiveObjectForKey:@"text"];
        searchItem.title = title[@"simpleText"];
        searchItem.videoId = pis;
        searchItem.imagePath = thumbnails.lastObject[@"url"];
        searchItem.resultType = YTSearchResultTypePlaylist;
        searchItem.details = [current recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"browseId"];
        [playlistResults addObject:searchItem];
    }];
    self.playlists = playlistResults;
    NSLog(@"enumerating channels!");
    [channels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"channel count > 0: %lu", channels.count);
        NSDictionary *current = obj[@"channelRenderer"];
        if (current) {
            NSLog(@"current: %@", [current allKeys]);
            NSDictionary *title = [current recursiveObjectForKey:@"title"];
            NSString *cis = current[@"channelId"];
            NSArray *thumbnails = current[@"thumbnail"][@"thumbnails"];
            NSDictionary *longBylineText = current[@"longBylineText"];
            KBYTSearchResult *searchItem = [KBYTSearchResult new];
            searchItem.author = [longBylineText recursiveObjectForKey:@"text"];
            searchItem.title = title[@"simpleText"];
            searchItem.videoId = cis;
            searchItem.imagePath = thumbnails.lastObject[@"url"];
            searchItem.resultType = YTSearchResultTypeChannel;
            searchItem.details = [current recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"browseId"];
            [channelResults addObject:searchItem];
        }
    }];
    self.channels = channelResults;
    NSLog(@"channelResults: %@", channelResults);
    self.estimatedResults = estimatedResults;
}

@end

@implementation KBYTLocalMedia

@synthesize author, title, images, inProgress, videoId, views, duration, extension, filePath, format, outputFilename;

- (id)initWithDictionary:(NSDictionary *)inputDict
{
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

- (NSDictionary *)dictionaryValue
{
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

- (NSString *)description
{
    return [[self dictionaryValue] description];
}

@end


/*
 
 KBYTSearchResult keep track of search results through the new HTML scraping search methods that supplanted
 the old web view that was used in earlier versions.
 
 */

@implementation KBYTSearchResult

@synthesize title, author, details, imagePath, videoId, duration, age, views, resultType;

- (id)initWithDictionary:(NSDictionary *)resultDict
{
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

- (NSString *)readableSearchType
{
    switch (self.resultType) {
        case YTSearchResultTypeUnknown: return @"Unknown";
        case YTSearchResultTypeVideo: return @"Video";
        case YTSearchResultTypePlaylist: return @"Playlist";
        case YTSearchResultTypeChannel: return @"Channel";
        case YTSearchResultTypeChannelList: return @"Channel List";
        default:
            return @"Unknown";
    }
}

- (NSDictionary *)dictionaryValue
{
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

- (NSString *)description
{
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

- (id)initWithDictionary:(NSDictionary *)streamDict
{
    self = [super init];
    
    if ([self processSource:streamDict] == true)
    {
        return self;
    }
    return nil;
}


- (BOOL)isExpired
{
    if ([NSDate passedEpochDateInterval:self.expireTime])
    {
        return true;
    }
    return false;
}


/**
 
 take the input dictionary and update our values according to it.
 
 */


- (BOOL)processSource:(NSDictionary *)inputSource
{
    //NSLog(@"inputSource: %@", inputSource);
    if ([[inputSource allKeys] containsObject:@"url"])
    {
        NSString *signature = nil;
        self.itag = [[inputSource objectForKey:@"itag"] integerValue];
        
        //if you want to limit to mp4 only, comment this if back in
        //  if (fmt == 22 || fmt == 18 || fmt == 37 || fmt == 38)
        //    {
        NSString *url = [[inputSource objectForKey:@"url"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if ([[inputSource allKeys] containsObject:@"sig"])
        {
            self.s = [inputSource objectForKey:@"sig"];
            signature = [inputSource objectForKey:@"sig"];
            url = [url stringByAppendingFormat:@"&signature=%@", signature];
        } else if ([[inputSource allKeys] containsObject:@"s"]) //requires cipher to update the signature
        {
            self.s = [inputSource objectForKey:@"s"];
            signature = [inputSource objectForKey:@"s"];
            signature = [[KBYourTube sharedInstance] decodeSignature:signature];
            //NSLog(@"decoded sig: %@", signature);
            url = [url stringByAppendingFormat:@"&signature=%@", signature];
        }
        
        NSDictionary *tags = [KBYourTube formatFromTag:self.itag];
        
        
        if (tags == nil) // unsupported format, return nil
        {
            return false;
        }
        
        if ([[inputSource valueForKey:@"quality"] length] == 0)
        {
            self.quality = tags[@"quality"];
        } else {
            self.quality = inputSource[@"quality"];
        }
        
        self.url = [NSURL URLWithString:url];
        self.expireTime = [[self.url parameterDictionary][@"expire"] integerValue];
        self.format = tags[@"format"]; //@{@"format": @"4K MP4", @"height": @2304, @"extension": @"mp4"}
        self.height = tags[@"height"];
        self.extension = tags[@"extension"];
        
        if (([self.extension isEqualToString:@"mp4"] || [self.extension isEqualToString:@"3gp"] ))
        {
            self.playable = true;
        } else {
            self.playable = false;
        }
        
        if (([self.extension isEqualToString:@"m4v"] || [self.extension isEqualToString:@"aac"] ))
        {
            self.multiplexed = false;
        } else {
            self.multiplexed = true;
        }
        
        self.type = [[[[inputSource valueForKey:@"type"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        self.title = [[[inputSource valueForKey:@"title"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        if (self.height == 0)
        {
            self.outputFilename = [NSString stringWithFormat:@"%@.%@", self.title,self.extension];
        } else {
            self.outputFilename = [NSString stringWithFormat:@"%@ [%@p].%@", self.title, self.height,self.extension];
        }
        return true;
        // }
    }
    
    
    return false;
}

- (NSDictionary *)dictionaryValue
{
    if (self.title == nil)self.title = @"Unavailable";
    if (self.type == nil)self.type = @"Unavailable";
    if (self.format == nil)self.format = @"Unavailable";
    if (self.height == nil)self.height = 0;
    if (self.extension == nil)self.extension = @"Unavailable";
    if (self.outputFilename == nil)self.outputFilename = @"Unavailable";
    
    return @{@"title": self.title, @"type": self.type, @"format": self.format, @"height": self.height, @"itag": [NSNumber numberWithInteger:self.itag], @"extension": self.extension, @"url": self.url, @"outputFilename": self.outputFilename};
}

- (NSString *)description
{
    return [[self dictionaryValue] description];
}


@end

@implementation YTPlayerItem

@synthesize associatedMedia;

- (NSString *)description
{
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

- (AVMetadataItem *)metadataItemWithIdentifier:(NSString *)identifier value:(id<NSObject, NSCopying>) value
{
    AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc]init];
    item.value = value;
    item.identifier = identifier;
    item.extendedLanguageTag = @"und";
    return [item copy];
}

#if TARGET_OS_TV
- (AVMetadataItem *)metadataArtworkItemWithImage:(UIImage *)image
{
    AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc]init];
    item.value = UIImagePNGRepresentation(image);
    item.dataType = (__bridge NSString * _Nullable)(kCMMetadataBaseDataType_PNG);
    item.identifier = AVMetadataCommonIdentifierArtwork;
    item.extendedLanguageTag = @"und";
    return item.copy;
}

#endif



- (YTPlayerItem *)playerItemRepresentation
{
    KBYTStream *firstStream = [self streams][0];
    
   
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

- (BOOL)isExpired
{
    if ([NSDate passedEpochDateInterval:self.expireTime])
    {
        return true;
    }
    return false;
}

//make sure if its an adaptive stream that we match the video streams with the proper audio stream.

- (void)matchAudioStreams
{
    KBYTStream *audioStream = [[self.streams filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"itag == 140"]]lastObject];
    for (KBYTStream *theStream in self.streams)
    {
        if ([theStream multiplexed] == false && theStream != audioStream)
        {
            //NSLog(@"adding audio stream to stream with itag: %lu", (long)theStream.itag);
            [theStream setAudioStream:audioStream];
        }
    }
}

- (id)initWithDictionary:(NSDictionary *)inputDict
{
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

- (BOOL)processDictionary:(NSDictionary *)vars
{
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
    if (desc != nil)
    {
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
    for (NSString *map in maps )
    {
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
    for (NSString *amap in adaptiveMaps )
    {
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

- (NSString *)expiredString
{
    if ([self isExpired]) return @"YES";
    return @"NO";
}

- (NSDictionary *)dictionaryRepresentation
{
    if (self.details == nil)self.details = @"Unavailable";
    if (self.keywords == nil)self.keywords = @"Unavailable";
    if (self.views == nil)self.views = @"Unavailable";
    if (self.duration == nil)self.duration = @"Unavailable";
    if (self.title == nil)self.title = @"Unavailable";
    if (self.images == nil)self.images = @{};
    if (self.streams == nil)self.streams = @[];
    return @{@"title": self.title, @"author": self.author, @"keywords": self.keywords, @"videoID": self.videoId, @"views": self.views, @"duration": self.duration, @"images": self.images, @"streams": self.streams, @"details": self.details, @"expireTime": [NSNumber numberWithInteger:self.expireTime], @"isExpired": [self expiredString]};
}

- (NSString *)description
{
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

- (NSDictionary *)paramsForChannelID:(NSString *)channelID {
    return @{ @"browseId": channelID,
              @"context":  @{ @"client":
                                  @{ @"clientName": @"WEB",
                                     @"clientVersion": @"2.20210408.08.00",
                                     @"hl": @"en",
                                     @"gl": @"US",
                                     @"utcOffsetMinutes": @0 } } };
}

- (NSDictionary *)paramsForPlaylist:(NSString *)playlistID {
    return @{ @"playlistId": playlistID,
              @"context":  @{ @"client":
                                  @{ @"clientName": @"WEB",
                                     @"clientVersion": @"2.20210408.08.00",
                                     @"hl": @"en",
                                     @"gl": @"US",
                                     @"utcOffsetMinutes": @0 } } };
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

+ (YTSearchResultType)resultTypeForString:(NSString *)string
{
    if ([string isEqualToString:@"Channel"]) return YTSearchResultTypeChannel;
    else if ([string isEqualToString:@"Playlist"]) return YTSearchResultTypePlaylist;
    else if ([string isEqualToString:@"Channel List"]) return YTSearchResultTypeChannelList;
    else if ([string isEqualToString:@"Video"]) return YTSearchResultTypeVideo;
     else if ([string isEqualToString:@"Unknown"]) return YTSearchResultTypeUnknown;
     else return YTSearchResultTypeUnknown;
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

- (void)documentFromURL:(NSString *)theURL completion:(void(^)(ONOXMLDocument *document))block
{

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

- (ONOXMLDocument *)documentFromURL:(NSString *)theURL
{
    //<li><div class="display-message"
    NSString *rawRequestResult = [self stringFromRequest:theURL];
    return [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
}

- (BOOL)isSignedIn
{
    ONOXMLDocument *xmlDoc = [self documentFromURL:@"https://www.youtube.com/feed/history"];
    ONOXMLElement *root = [xmlDoc rootElement];
    ONOXMLElement * displayMessage = [root firstChildWithXPath:@"//div[contains(@class, 'display-message')]"];
    NSString *displayMessageString = [displayMessage stringValue];
    NSLog(@"dms: %@", displayMessageString);
    if (displayMessageString.length == 0 || displayMessageString == nil)
    {
       // [TYAuthUserManager]
        return true;
    }
    return false;

}

- (NSInteger)videoCountForChannel:(NSString *)channelID
{
    DLog(@"videoCountForChannel: %@", channelID);
    //channels-browse-content-grid
    //channels-content-item
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@/videos", channelID]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    NSArray *objects = [(NSEnumerator *)[canon XPath:@".//li[contains(@class, 'channels-content-item')]"] allObjects];
    return [objects count];
}

- (NSInteger)videoCountForUserName:(NSString *)channelID
{
    //channels-browse-content-grid
    //channels-content-item
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/user/%@/videos", channelID]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    NSArray *objects = [(NSEnumerator *)[canon XPath:@".//li[contains(@class, 'channels-content-item')]"] allObjects];
    return [objects count];
}


- (void)getUserDetailsDictionaryWithCompletionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                                       failureBlock:(void(^)(NSString *error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            BOOL signedIn = [self isSignedIn];
            NSString *errorString = @"Unknown error occurred";
            NSMutableDictionary *returnDict = [NSMutableDictionary new];
            if (signedIn == true) {
                
                NSDictionary *channelDict = [self channelIDAndWatchLaterCount];
                NSLog(@"[yourTubeiOS] channelDict: %@", channelDict);
                NSString *channelID = channelDict[@"channelID"];
                NSDictionary *ourUserDetails = [self userDetailsFromChannelURL:channelID];
                if (ourUserDetails == nil)
                {
                    NSLog(@"false positive on signed in, bail");
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
                userChannel.resultType = YTSearchResultTypeChannel;
                [itemArray addObject:userChannel];
                
                NSInteger wlCount = [channelDict[@"wlCount"] integerValue];
                if (wlCount > 0){
                KBYTSearchResult *wlPl = [KBYTSearchResult new];
                wlPl.author = userName;
                wlPl.videoId = @"WL";
                wlPl.details = [NSString stringWithFormat:@"%lu videos", wlCount];
                wlPl.title = @"Watch later";
                wlPl.imagePath = ourUserDetails[@"profileImage"];
                wlPl.resultType = YTSearchResultTypePlaylist;
                
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

- (NSDictionary *)channelIDAndWatchLaterCount
{
    ONOXMLDocument *xmlDoc = [self documentFromURL:@"https://m.youtube.com"];
    ONOXMLElement *root = [xmlDoc rootElement];
   /* NSArray *itemCounts = [(NSEnumerator *)[root XPath:@".//span[contains(@class, 'yt-valign-container guide-count-value')]"] allObjects];
    NSString *watchLaterCount = @"1";
    if (itemCounts.count > 1)
    {
    
        watchLaterCount = [[itemCounts objectAtIndex:1] stringValue];
    }
    */
    NSString *watchLaterCount = [NSString stringWithFormat:@"%lu", [self watchLaterCount]];
    ONOXMLElement *guideSection = [root firstChildWithXPath:@"//li[contains(@class, 'guide-section')]"];
    NSArray *allObjects = [(NSEnumerator *)[guideSection XPath:@".//a[contains(@class, 'guide-item')]"] allObjects];
    if ([allObjects count] > 1)
    {
        ONOXMLElement *channelElement = [allObjects objectAtIndex:1];
        if ([channelElement valueForAttribute:@"href"] != nil && watchLaterCount != nil)
        {
        return @{@"channelID": [[channelElement valueForAttribute:@"href"] lastPathComponent], @"wlCount": watchLaterCount};
        }
    }
    
    //<span class="yt-valign-container guide-count-value">4</span>
    return nil;
}

- (NSString *)channelID
{
    ONOXMLDocument *xmlDoc = [self documentFromURL:@"https://m.youtube.com"];
    ONOXMLElement *root = [xmlDoc rootElement];
    ONOXMLElement *guideSection = [root firstChildWithXPath:@"//li[contains(@class, 'guide-section')]"];
    NSArray *allObjects = [(NSEnumerator *)[guideSection XPath:@".//a[contains(@class, 'guide-item')]"] allObjects];
    if ([allObjects count] > 1)
    {
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

- (NSDictionary *)userDetailsFromChannelURL:(NSString *)channelURL
{
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@", channelURL]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//link[contains(@rel, 'canonical')]"];
    
    //<img class="channel-header-profile-image" src="//i.ytimg.com/i/iuFEQ2-YiaW97Uzu00bOZQ/mq1.jpg?v=564b8e92" title="nito" alt="nito">
    NSString *profileImage = [[root firstChildWithXPath:@"//img[contains(@class, 'channel-header-profile-image')]"] valueForAttribute:@"src"];
    
    NSString *altUserName = [[[root firstChildWithXPath:@"//meta"] valueForAttribute:@"content"] lowercaseString];
    
    //get the high quality version instead of the mq crappy one.
    profileImage = [profileImage stringByReplacingOccurrencesOfString:@"/mq" withString:@"/hq"];
    
    
    if (canon != nil & profileImage != nil)
    {
        
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

- (NSString *)userNameFromChannelURL:(NSString *)channelURL
{
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@", channelURL]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//link[contains(@rel, 'canonical')]"];
    return [[canon valueForAttribute:@"href"] lastPathComponent];
}

- (NSDictionary *)videoChannelsList:(NSString *)channelID
{
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
    
    while (currentElement = [videoEnum nextObject])
    {
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

- (NSArray *)playlistArrayFromChannel:(NSString *)channel
{
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@/playlists?sort=da&flow=grid&view=1", channel]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *playlistGroup = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    id playlistEnum = [playlistGroup XPath:@".//li[contains(@class, 'channels-content-item')]"];
    ONOXMLElement *playlistElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    while (playlistElement = [playlistEnum  nextObject])
    {
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
        result.resultType = YTSearchResultTypePlaylist;
        //NSDictionary *playlistItem = @{@"thumbURL": [NSString stringWithFormat:@"https:%@", thumbPath], @"title": playlistTitle, @"URL": playlistURL, @"videoCount": videoCount};
        [finalArray addObject:result];
        
    }
    return finalArray;
}

- (NSArray *)playlistArrayFromUserName:(NSString *)userName
{
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/%@/playlists?sort=da&flow=grid&view=1", userName]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *playlistGroup = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    id playlistEnum = [playlistGroup XPath:@".//li[contains(@class, 'channels-content-item')]"];
    ONOXMLElement *playlistElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    while (playlistElement = [playlistEnum  nextObject])
    {
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
        result.resultType = YTSearchResultTypePlaylist;
        //NSDictionary *playlistItem = @{@"thumbURL": [NSString stringWithFormat:@"https:%@", thumbPath], @"title": playlistTitle, @"URL": playlistURL, @"videoCount": videoCount};
        [finalArray addObject:result];
        
    }
    return finalArray;
}


///aircontrol code, this is used to play media straight into firecore's youtube appliance on ATV 2

- (void)playMedia:(KBYTMedia *)media ToDeviceIP:(NSString *)deviceIP
{
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
- (void)pauseAirplay
{
    [[KBYTMessagingCenter sharedInstance] pauseAirplay];
}

- (void)stopAirplay
{
    [[KBYTMessagingCenter sharedInstance] stopAirplay];
}

- (NSInteger)airplayStatus
{
    return [[KBYTMessagingCenter sharedInstance] airplayStatus];
}

- (void)airplayStream:(NSString *)stream ToDeviceIP:(NSString *)deviceIP
{
    [[KBYTMessagingCenter sharedInstance] airplayStream:stream ToDeviceIP:deviceIP];
    
}

#endif

- (NSDictionary *)returnFromURLRequest:(NSString *)requestString requestType:(NSString *)type
{
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
    
    NSURLResponse *response = nil;
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSData *json = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingFragmentsAllowed error:nil];
    [request setHTTPBody:json];
    //[request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B410 Safari/600.1.4" forHTTPHeaderField:@"User-Agent"];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
}

- (NSInteger)resultNumber:(NSString *)html
{
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

- (NSDictionary *)videoDetailsFromID:(NSString *)videoID
{
    NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", videoID];
    NSString *request = [self stringFromRequest:requestString];
    ONOXMLDocument *document = [ONOXMLDocument HTMLDocumentWithString:request encoding:NSUTF8StringEncoding error:nil];
    ONOXMLElement *root = [document rootElement];
    NSString *XPath = @"//div/meta";
    id titleEnum = [root XPath:XPath];
    
    NSMutableDictionary *detailsDict = [NSMutableDictionary new];
    
    id theObject = nil;
    while (theObject = [titleEnum nextObject])
    {
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

- (NSString *)videoDescription:(NSString *)videoID
{
    NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", videoID];
    NSString *request = [self stringFromRequest:requestString];
    NSString *trimmed = [self videoInfoPage:request];
    APDocument *rawDoc = [[APDocument alloc] initWithString:trimmed];
    APElement *descElement = [[rawDoc rootElement] elementContainingNameString:@"description"];
    return [descElement valueForAttributeNamed:@"content"];
}

- (void)getVideoDescription:(NSString *)videoID
            completionBlock:(void(^)(NSString* description))completionBlock
               failureBlock:(void(^)(NSString* error))failureBlock
{
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

- (NSInteger)watchLaterCount
{
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
          completionBlock:(void(^)(KBYTPlaylist *playlist))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSString *errorString = nil;
            NSString *url = [self nextURL];
            NSLog(@"url: %@", url);
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForPlaylist:listID];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            //NSLog(@"body: %@ for: %@ %@", jsonDict, url, params);
            NSDictionary *plRoot = [jsonDict recursiveObjectForKey:@"playlist"][@"playlist"];
            NSString *owner = [plRoot recursiveObjectForKey:@"ownerName"][@"simpleText"];
            NSString *title = plRoot[@"title"];
            //NSLog(@"owner: %@ title: %@", owner, title);
            KBYTPlaylist *playlist = [KBYTPlaylist new];
            playlist.owner = owner;
            playlist.title = title;
            playlist.playlistID = listID;
            __block NSMutableArray *videos = [NSMutableArray new];
            NSArray *vr = [jsonDict recursiveObjectsForKey:@"playlistPanelVideoRenderer"];
            //NSLog(@"vr: %@", vr);
            //[plRoot writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"root.plist"] atomically:true];
            [vr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                //NSLog(@"%@", obj[@"playlistPanelVideoRenderer"]);
                NSDictionary *current = obj[@"playlistPanelVideoRenderer"];
                if (current) {
                    //NSLog(@"current: %@", current);
                    //NSLog(@"keys: %@", [current allKeys]);
                    NSString *lengthText = current[@"lengthText"][@"simpleText"];
                    NSDictionary *title = current[@"title"];
                    NSString *vid = current[@"videoId"];
                    NSArray *thumbnails = current[@"thumbnail"][@"thumbnails"];
                    NSDictionary *longBylineText = current[@"longBylineText"];
                    KBYTSearchResult *searchItem = [KBYTSearchResult new];
                    searchItem.details = [longBylineText recursiveObjectForKey:@"text"];
                    searchItem.author = searchItem.details;
                    searchItem.title = [title recursiveObjectForKey:@"simpleText"];
                    searchItem.duration = lengthText;
                    searchItem.videoId = vid;
                    searchItem.resultType = YTSearchResultTypeVideo;
                    searchItem.imagePath = thumbnails.lastObject[@"url"];
                    [videos addObject:searchItem];
                } else {
                    NSLog(@"no vr: %@", [obj allKeys]);
                }
            }];
            playlist.videos = videos;
            //NSLog(@"videos: %@", videos);
            //NSLog(@"root info: %@", rootInfo);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(jsonDict != nil) {
                    completionBlock(playlist);
                } else {
                    failureBlock(errorString);
                }
            });
        }
    });
    
}

- (void)loadMorePlaylistVideosFromHREF:(NSString *)loadMoreLink
                       completionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                          failureBlock:(void(^)(NSString *error))failureBlock
{
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
                result.resultType = YTSearchResultTypeVideo;
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
                  failureBlock:(void(^)(NSString *error))failureBlock
{
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
                result.resultType = YTSearchResultTypeVideo;
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

- (NSArray *)channelArrayFromChannel:(NSString *)userName
{
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@/channels?view=56&shelf_id=0", userName]];
    ONOXMLElement *root = [xmlDoct rootElement];
    // NSLog(@"root: %@", root);
    ONOXMLElement *playlistGroup = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    id playlistEnum = [playlistGroup XPath:@".//li[contains(@class, 'channels-content-item')]"];
    ONOXMLElement *playlistElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    while (playlistElement = [playlistEnum  nextObject])
    {
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
        result.resultType = YTSearchResultTypeChannel;
        //NSDictionary *playlistItem = @{@"thumbURL": [NSString stringWithFormat:@"https:%@", thumbPath], @"title": playlistTitle, @"URL": playlistURL, @"videoCount": videoCount};
        [finalArray addObject:result];
        //[finalArray addObject:playlistItem];
        
    }
    return finalArray;
}

- (NSArray *)channelArrayFromUserName:(NSString *)userName
{
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/%@/channels?view=56&shelf_id=0", userName]];
    ONOXMLElement *root = [xmlDoct rootElement];
    // NSLog(@"root: %@", root);
    ONOXMLElement *playlistGroup = [root firstChildWithXPath:@"//ul[contains(@id, 'channels-browse-content-grid')]"];
    id playlistEnum = [playlistGroup XPath:@".//li[contains(@class, 'channels-content-item')]"];
    ONOXMLElement *playlistElement = nil;
    NSMutableArray *finalArray = [NSMutableArray new];
    while (playlistElement = [playlistEnum  nextObject])
    {
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
        result.resultType = YTSearchResultTypeChannel;
        //NSDictionary *playlistItem = @{@"thumbURL": [NSString stringWithFormat:@"https:%@", thumbPath], @"title": playlistTitle, @"URL": playlistURL, @"videoCount": videoCount};
        [finalArray addObject:result];
        //[finalArray addObject:playlistItem];
        
    }
    return finalArray;
}


- (void)getUserVideos:(NSString *)channelID
          completionBlock:(void(^)(NSDictionary *searchDetails))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock
{
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
                
                result.resultType = YTSearchResultTypeVideo;
                
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
    NSDictionary *title = current[@"title"];
    NSString *fullTitle = [title recursiveObjectForKey:@"text"];
    if (!fullTitle) {
        fullTitle = [title recursiveObjectForKey:@"simpleText"];
    }
    NSString *vid = current[@"videoId"];
    NSString *viewCountText = current[@"viewCountText"][@"simpleText"];
    NSArray *thumbnails = current[@"thumbnail"][@"thumbnails"];
    NSDictionary *longBylineText = current[@"longBylineText"];
    if (!longBylineText) {
        longBylineText = [current recursiveObjectForKey:@"shortBylineText"];
    }
    NSDictionary *ownerText = current[@"ownerText"];
    if (!ownerText) {
        ownerText = longBylineText;
    }
    KBYTSearchResult *searchItem = [KBYTSearchResult new];
    searchItem.details = [longBylineText recursiveObjectForKey:@"text"];
    searchItem.author = [ownerText recursiveObjectForKey:@"text"];
    searchItem.title = fullTitle;
    searchItem.duration = lengthText;
    searchItem.videoId = vid;
    searchItem.views = viewCountText;
    searchItem.age = current[@"publishedTimeText"][@"simpleText"];
    searchItem.imagePath = thumbnails.lastObject[@"url"];
    searchItem.resultType = YTSearchResultTypeVideo;
    return searchItem;
}


- (void)getChannelVideosAlt:(NSString *)channelID
          completionBlock:(void(^)(KBYTChannel *channel))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSString *url = [self browseURL];
            //get the post body from the url above, gets the initial raw info we work with
            NSDictionary *params = [self paramsForChannelID:channelID];
            NSString *body = [self stringFromPostRequest:url withParams:params];
            NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
            //NSLog(@"body: %@ for: %@ %@", jsonDict, url, params);
            //NSMutableArray* arr = [NSMutableArray array];
            //[self obtainKeyPaths:jsonDict intoArray:arr withString:nil];
            //[arr writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"gaming.keypaths.plist"] atomically:true];
            id cc = [jsonDict recursiveObjectForKey:@"continuationCommand"];
            //DLog(@"cc: %@", cc);
            __block NSMutableArray *items = [NSMutableArray new];
            NSDictionary *grid = [jsonDict recursiveObjectForKey:@"richGridRenderer"];
            NSDictionary *details = [jsonDict recursiveObjectForKey:@"topicChannelDetailsRenderer"];
            if (!grid) {
                grid = [jsonDict recursiveObjectForKey:@"sectionListRenderer"];
            }
            if (!details) {
                details = [jsonDict recursiveObjectForKey:@"channelMetadataRenderer"];
                //DLog(@"details: %@", details);
            }
            NSDictionary *title = [details recursiveObjectForKey:@"title"];
            NSDictionary *subtitle = [details recursiveObjectForKey:@"subtitle"];
            NSArray *thumbnails = [details recursiveObjectForKey:@"thumbnails"];
            KBYTChannel *channel = [KBYTChannel new];
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
            channel.image = thumbnails.lastObject[@"url"];
            channel.url = [details recursiveObjectForKey:@"navigationEndpoint"][@"browseEndpoint"][@"canonicalBaseUrl"];
            channel.continuationToken = cc[@"token"];
            //DLog(@"details: %@", details);
            //title,subtitle,thumbnails
            NSArray *contents = grid[@"contents"];
            [contents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *contents = [obj recursiveObjectForKey:@"contents"];
                if (contents) {
                    //DLog(@"%lu is a shelf object", idx);
                    [contents enumerateObjectsUsingBlock:^(id  _Nonnull obj2, NSUInteger idx2, BOOL * _Nonnull stop2) {
                        NSDictionary *videoR = [obj2 recursiveObjectForKey:@"videoRenderer"];
                        if (videoR) {
                            KBYTSearchResult *result = [self searchResultFromVideoRenderer:videoR];
                            //DLog(@"shelf item %lu subindex %lu is a video object", idx, idx2);
                            [items addObject:result];
                        } else { //check for the horizontal lists...
                            
                            NSArray *vrTest = [obj2 recursiveObjectsLikeKey:@"videoRenderer"];
                            if (vrTest){
                                //DLog(@"vrTest: %lu", vrTest.count);
                                [vrTest enumerateObjectsUsingBlock:^(id  _Nonnull hlistObj, NSUInteger hListIdx, BOOL * _Nonnull hListStop) {
                                    NSDictionary *videoR = [hlistObj recursiveObjectLikeKey:@"videoRenderer"];
                                    if (videoR) {
                                        //DLog(@"vrTest item %lu subindex %lu is a video object", hListIdx, idx2);
                                        KBYTSearchResult *res = [self searchResultFromVideoRenderer:videoR];
                                        //DLog(@"%@", res);
                                        [items addObject:res];
                                    }
                                }];
                            }
                            /*
                            NSArray *horizList = [obj2 recursiveObjectForKey:@"horizontalListRenderer"][@"items"];
                            if (horizList) {
                                DLog(@"horiz: %lu", horizList.count);
                                //DLog(@"got a horiz list");
                                [horizList enumerateObjectsUsingBlock:^(id  _Nonnull hlistObj, NSUInteger hListIdx, BOOL * _Nonnull hListStop) {
                                    NSDictionary *videoR = [hlistObj recursiveObjectForKey:@"gridVideoRenderer"];
                                    if (videoR) {
                                        //DLog(@"horiz item %lu subindex %lu is a video object", hListIdx, idx2);
                                        KBYTSearchResult *res = [self searchResultFromVideoRenderer:videoR];
                                        //DLog(@"%@", res);
                                        [items addObject:res];
                                    }
                                }];
                            } else {
                                NSArray *horizList = [obj2 recursiveObjectForKey:@"gridRenderer"][@"items"];
                                if (horizList) {
                                    DLog(@"horiz: %lu", horizList.count);
                                    //DLog(@"found gridRenderer list: %lu", horizList.count);
                                    [horizList enumerateObjectsUsingBlock:^(id  _Nonnull hlistObj, NSUInteger hListIdx, BOOL * _Nonnull hListStop) {
                                        NSDictionary *videoR = [hlistObj recursiveObjectForKey:@"gridVideoRenderer"];
                                        if (videoR) {
                                            //DLog(@"horiz item %lu subindex %lu is a video object", hListIdx, idx2);
                                            KBYTSearchResult *res = [self searchResultFromVideoRenderer:videoR];
                                            //DLog(@"%@", res);
                                            [items addObject:res];
                                        }
                                    }];
                                }
                            }
                            */
                        }
                    }];
                } else { //should be a singular object
                    DLog(@"%lu is a singular object: %@", idx, contents);
                    NSDictionary *videoR = [obj recursiveObjectForKey:@"videoRenderer"];
                    if (videoR) {
                        KBYTSearchResult *result = [self searchResultFromVideoRenderer:videoR];
                        DLog(@"%lu is a video object", idx);
                        [items addObject:result];
                    }
                }
            }];
            
            channel.channelID = channelID;
            channel.videos = items;
            //get the post body from the url above, gets the initial raw info we work with
            if (completionBlock) {
                completionBlock(channel);
            }
        }
    });
    
}

- (void)getChannelVideos:(NSString *)channelID
          completionBlock:(void(^)(KBYTChannel *channel))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock
{
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
            [self getPlaylistVideos:newChannelID completionBlock:^(KBYTPlaylist *playlist) {
                channel.videos = playlist.videos;
                completionBlock(channel);
            } failureBlock:^(NSString *error) {
                failureBlock(nil);
            }];
        }
    });
    
}

- (void)getOrganizedChannelData:(NSString *)channelID
                       completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
                          failureBlock:(void(^)(NSString* error))failureBlock;
{
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
                    result.resultType = YTSearchResultTypeVideo;
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
                        result.resultType = YTSearchResultTypeVideo;
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
                        result.resultType = YTSearchResultTypeVideo;
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

- (void)getAllFeaturedVideosWithFilter:(NSString *)filter
                       completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
                          failureBlock:(void(^)(NSString* error))failureBlock;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            NSString *requestString = @"https://m.youtube.com/";
            if (filter != nil)
            {
                requestString = [requestString stringByAppendingPathComponent:[NSString stringWithFormat:@"feed/%@", filter]];
            }
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
            
            id sectionEnum = [sectionListElement XPath:@"//ol[contains(@class, 'item-section')]"];
            
            ONOXMLElement *videosElement = nil;
            //  NSMutableArray *videoArray = [NSMutableArray new];
            NSMutableDictionary *finalDict = [NSMutableDictionary new];
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
                //NSMutableDictionary *outputDict = [NSMutableDictionary new];
                while (currentElement = [videoEnum nextObject])
                {
                    //NSMutableDictionary *scienceDict = [NSMutableDictionary new];
                    KBYTSearchResult *result = [KBYTSearchResult new];
                    NSString *videoID = [currentElement valueForAttribute:@"data-context-item-id"];
                    if (videoID != nil)
                    {
                        result.videoId = videoID;
                    }
                    result.resultType = YTSearchResultTypeVideo;
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
                    
                    channelDict[@"videos"] = finalArray;
                    finalDict[channelName] = channelDict;
                }
            }
            
            
            

            if ([finalDict.allKeys count] > 0)
            {
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
                                failureBlock:(void(^)(NSString* error))failureBlock;
{
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
                result.resultType = YTSearchResultTypeVideo;
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

- (NSString *)attemptConvertImagePathToHiRes:(NSString *)imagePath
{
    if ([imagePath rangeOfString:@"custom=true"].location == NSNotFound)
    {
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
                failureBlock:(void(^)(NSString* error))failureBlock
{
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
            [results processJSON:jsonDict];
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



/**
 
 This will get ALL the info about EVERY search result. it initially just compiles a list of video ID's scraping
 youtubes search, this scrape should be MUCH less fragile. However, since it runs through get_video_info
 with EVERY video id its a LOT slower then the basic search above. so it would be better to use as a
 fallback if the one above fails.
 
 */

- (void)getSearchResults:(NSString *)searchQuery
              pageNumber:(NSInteger)page
         completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
            failureBlock:(void(^)(NSString* error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            NSString *pageorsm = nil;
            if (page == 1)
            {
                pageorsm = @"sm=1";
            } else {
                pageorsm = [NSString stringWithFormat:@"page=%lu", page];
            }
            NSString *requestString = [NSString stringWithFormat:@"https://m.youtube.com/results?q=%@&%@", [searchQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pageorsm];
            
            NSString *request = [self stringFromRequest:requestString];
            NSInteger results = [self resultNumber:request];
            NSArray *videoIDs = [self ytSearchBasics:request];
            NSInteger pageCount = results/[videoIDs count];
            NSMutableDictionary *outputDict = [NSMutableDictionary new];
            [outputDict setValue:[NSNumber numberWithInteger:results] forKey:@"resultCount"];
            [outputDict setValue:[NSNumber numberWithInteger:pageCount] forKey:@"pageCount"];
            NSMutableArray *finalArray = [NSMutableArray new];
            //NSMutableDictionary *rootInfo = [NSMutableDictionary new];
            NSString *errorString = nil;
            
            //if we already have the timestamp and key theres no reason to fetch them again, should make additional calls quicker.
            if (self.yttimestamp.length == 0 && self.ytkey.length == 0)
            {
                //get the time stamp and cipher key in case we need to decode the signature.
                [self getTimeStampAndKey:[videoIDs firstObject]];
            }
            
            //a fallback just in case the jsbody is changed and we cant automatically grab current signatures
            //old ciphers generally continue to work at least temporarily.
            
            if (self.yttimestamp.length == 0 || self.ytkey.length == 0)
            {
                errorString = @"Failed to decode signature cipher javascript.";
                self.yttimestamp = hardcodedTimestamp;
                self.ytkey = hardcodedCipher;
                
            }
            
            //the url we use to call get_video_info
            
            
            
            for (NSString *videoID in videoIDs) {
                
                NSString *url = [NSString stringWithFormat:@"https://www.youtube.com/get_video_info?&video_id=%@&%@&sts=%@", videoID, @"eurl=http%3A%2F%2Fwww%2Eyoutube%2Ecom%2F", self.yttimestamp];
                
                //get the post body from the url above, gets the initial raw info we work with
                NSString *body = [self stringFromRequest:url];
                
                //turn all of these variables into an nsdictionary by separating elements by =
                NSDictionary *vars = [self parseFlashVars:body];
                
                //  NSLog(@"vars: %@", vars);
                
                if ([[vars allKeys] containsObject:@"status"])
                {
                    if ([[vars objectForKey:@"status"] isEqualToString:@"ok"])
                    {
                        //the call was successful, create our root object.
                        KBYTMedia *currentMedia = [[KBYTMedia alloc] initWithDictionary:vars];
                        [finalArray addObject:currentMedia];
                    }
                } else {
                    
                    errorString = @"get_video_info failed.";
                    
                }
                
            }
            [outputDict setValue:finalArray forKey:@"results"];
            
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

#pragma mark video details

/*
 
 the only function you should ever have to call to get video streams
 take the video ID from a youtube link and feed it in to this function
 
 ie _7nYuyfkjCk from the link below include blocks for failure and success.
 
 
 https://www.youtube.com/watch?v=_7nYuyfkjCk
 
 
 */


- (void)getVideoDetailsForSearchResults:(NSArray*)searchResults
                        completionBlock:(void(^)(NSArray* videoArray))completionBlock
                           failureBlock:(void(^)(NSString* error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSMutableArray *finalArray = [NSMutableArray new];
            //NSMutableDictionary *rootInfo = [NSMutableDictionary new];
            NSString *errorString = nil;
            
            NSInteger i = 0;
            
            for (KBYTSearchResult *result in searchResults) {
                
                NSString *url = [self playerURL];
                NSLog(@"url: %@", url);
                //get the post body from the url above, gets the initial raw info we work with
                NSDictionary *params = [self paramsForVideo:result.videoId];
                NSString *body = [self stringFromPostRequest:url withParams:params];
                NSData *jsonData = [body dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments|NSJSONReadingMutableLeaves error:nil];
                KBYTMedia *currentMedia = [[KBYTMedia alloc] initWithJSON:jsonDict];
                [finalArray addObject:currentMedia];
                
                //    NSLog(@"processing videoID %@ at index: %lu", result.videoId, i);
                /*
                if ([result media] != nil && [[result media] isExpired] == false) //skip it if we've already fetched it.
                {
                    [finalArray addObject:[result media]];
                    continue;
                }
                NSString *url = [NSString stringWithFormat:@"https://www.youtube.com/get_video_info?&video_id=%@&%@&sts=%@", result.videoId, @"eurl=http%3A%2F%2Fwww%2Eyoutube%2Ecom%2F", self.yttimestamp];
                
                //get the post body from the url above, gets the initial raw info we work with
                NSString *body = [self stringFromRequest:url];
                
                //turn all of these variables into an nsdictionary by separating elements by =
                NSDictionary *vars = [self parseFlashVars:body];
                
                //  NSLog(@"vars: %@", vars);
                
                if ([[vars allKeys] containsObject:@"status"])
                {
                    if ([[vars objectForKey:@"status"] isEqualToString:@"ok"])
                    {
                        //the call was successful, create our root object.
                        KBYTMedia *currentMedia = [[KBYTMedia alloc] initWithDictionary:vars];
                        // NSLog(@"adding media: %@", currentMedia);
                        result.media = currentMedia;
                        [finalArray addObject:currentMedia];
                    } else {
                        
                        errorString = [[[vars objectForKey:@"reason"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];
                        NSLog(@"get_video_info for %@ failed for reason: %@", result.title, errorString);
                        
                    }
                } else {
                    
                    errorString = @"get_video_info failed.";
                    NSLog(@"get video info failed for id: %@", result.videoId);
                }
                i++;
                 */
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
                 failureBlock:(void(^)(NSString* error))failureBlock
{
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
                /*
                NSLog(@"processing videoID %@ at index: %lu", videoID, i);
                
                NSString *url = [NSString stringWithFormat:@"https://www.youtube.com/get_video_info?&video_id=%@&%@&sts=%@", videoID, @"eurl=http%3A%2F%2Fwww%2Eyoutube%2Ecom%2F", self.yttimestamp];
                
                //get the post body from the url above, gets the initial raw info we work with
                NSString *body = [self stringFromRequest:url];
                
                //turn all of these variables into an nsdictionary by separating elements by =
                NSDictionary *vars = [self parseFlashVars:body];
                
                //  NSLog(@"vars: %@", vars);
                
                if ([[vars allKeys] containsObject:@"status"])
                {
                    if ([[vars objectForKey:@"status"] isEqualToString:@"ok"])
                    {
                        //the call was successful, create our root object.
                        KBYTMedia *currentMedia = [[KBYTMedia alloc] initWithDictionary:vars];
                        // NSLog(@"adding media: %@", currentMedia);
                        [finalArray addObject:currentMedia];
                    } else {
                        
                        errorString = [[[vars objectForKey:@"reason"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];
                        NSLog(@"get_video_info for %@ failed for reason: %@", videoID, errorString);
                        
                    }
                } else {
                    
                    errorString = @"get_video_info failed.";
                    NSLog(@"get video info failed for id: %@", videoID);
                }
                i++;
                 */
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


- (void)importFileWithJO:(NSString *)theFile duration:(NSInteger)duration
{
    #if TARGET_OS_IOS
    NSDictionary *info = @{@"filePath": theFile, @"duration": [NSNumber numberWithInteger:duration]};
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.importscience"];
    [center sendMessageName:@"org.nito.importscience.import" userInfo:info];
#endif
}



//useful display details based on the itag
+ (NSDictionary *)formatFromTag:(NSInteger)tag
{
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


#pragma mark Signature deciphering

/*
 **
 ***
 
 Signature cipher notes
 
 the youtube signature cipher has 3 basic steps (for now) swapping, splicing and reversing
 the notes from youtubedown put it better than i can think to
 
 # - r  = reverse the string;
 # - sN = slice from character N to the end;
 # - wN = swap 0th and Nth character.
 
 they store their key a little differently then the clicktoplugin scripts yourTube code was based on
 
 their "w13 r s3 w2 r s3 w36" is the equivalent to our "13,0,-3,2,0,-3,36"
 
 the functions below take care of all of these steps.
 
 Processing a key example:
 
 13,0,-3,2,0,-3,36 would be processed the following way
 
 13: swap 13 character with character at 0
 0: reverse
 -3: splice from 3 to the end
 2: swap 2nd character with character at 0
 0: reverse
 -3: splice from 3 to the end
 36: swap 36 character with chracter at 0
 
 old sig: B52252CF80D5C2877E88D52375768FE00F29CD28A8B.A7322D9C40F39C2E32D30699152165DA9D282501501
 
 swap 13: B with 2
 swapped: 252252CF80D5CB877E88D52375768FE00F29CD28A8B.A7322D9C40F39C2E32D30699152165DA9D282501501
 
 reversed: 105105282D9AD56125199603D23E2C93F04C9D2237A.B8A82DC92F00EF86757325D88E778BC5D08FC252252
 
 sliced at 3: 105282D9AD56125199603D23E2C93F04C9D2237A.B8A82DC92F00EF86757325D88E778BC5D08FC252252
 
 swap 2: 1 with 5
 swapped: 501282D9AD56125199603D23E2C93F04C9D2237A.B8A82DC92F00EF86757325D88E778BC5D08FC252252
 
 reversed: 252252CF80D5CB877E88D52375768FE00F29CD28A8B.A7322D9C40F39C2E32D30699152165DA9D282105
 
 sliced 3: 252CF80D5CB877E88D52375768FE00F29CD28A8B.A7322D9C40F39C2E32D30699152165DA9D282105
 
 swap 36: 2 with 8
 swapped: 852CF80D5CB877E88D52375768FE00F29CD22A8B.A7322D9C40F39C2E32D30699152165DA9D282105
 
 newsig: 852CF80D5CB877E88D52375768FE00F29CD22A8B.A7322D9C40F39C2E32D30699152165DA9D282105
 
 */

/**
 
 if use_cipher_signature is true the a timestamp and a key are necessary to decipher the signature and re-add it
 to the url for proper playback and download, this method will attempt to grab those values dynamically
 
 for more details look at https://www.jwz.org/hacks/youtubedown and search for this text
 
 24-Jun-2013: When use_cipher_signature=True
 
 didnt want to plagiarize his whole thesis, and its a good explanation of why this is necessary
 
 
 */


- (void)getTimeStampAndKey:(NSString *)videoID
{
    NSString *url = [NSString stringWithFormat:@"https://www.youtube.com/embed/%@", videoID];
    NSString *body = [self stringFromRequest:url];
    
    //the timestamp that is needed for signature deciphering
    
    self.yttimestamp = [[[[self matchesForString:body withRegex:@"\"sts\":(\\d*)"] lastObject] componentsSeparatedByString:@":"] lastObject];
    
    //isolate the base.js file that we need to extract the signature from
    
    NSString *baseJS = [NSString stringWithFormat:@"https://youtube.com%@", [[[[[self matchesForString:body withRegex:@"\"js\":\"([^\"]*)\""] lastObject] componentsSeparatedByString:@":"] lastObject] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"]];
    
    //get the raw js source of the decoder file that we need to get the signature cipher from
    
    
    NSString *jsBody = [self stringFromRequest:[baseJS stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
    
    //crazy convoluted regex to get a signature section similiar to this
    //cr.Ww(a,13);cr.W9(a,69);cr.Gz(a,3);cr.Ww(a,2);cr.W9(a,79);cr.Gz(a,3);cr.Ww(a,36);return a.join(
    
    //#### IGNORE THE WARNING, if the extra escape is added as expected the regex doesnt work!
    
    NSString *keyMatch = [[self matchesForString:jsBody withRegex:@"function[ $_A-Za-z0-9]*\\(a\\)\\{a=a(?:\.split|\\[[$_A-Za-z0-9]+\\])\\(\"\"\\);\\s*([^\"]*)"] lastObject];
    
    
    if ([keyMatch rangeOfString:@"function"].location != NSNotFound)
    {
        //find first ; and make substring from there.
        NSUInteger loc = [keyMatch rangeOfString:@";"].location;
        //DLog(@"loc: %lu", loc);
        keyMatch = [keyMatch substringFromIndex:loc+1];
    }
    
    //the jsbody is trimmed down to a smaller section to optimize the search to deobfuscate the signature function names
    
    NSString *fnNameMatch = [NSString stringWithFormat:@";var %@={", [[self matchesForString:keyMatch withRegex:@"^[$_A-Za-z0-9]+"] lastObject]];
    
    //the index to start the new string range from for said optimization above
    
    NSUInteger index = [jsBody rangeOfString:fnNameMatch].location;
    
    //smaller string for searching for reverse / splice function names
    NSString *x = [jsBody substringFromIndex:index];
    NSString *a, *tmp, *r, *s = nil;
    
    //next baffling regex used to cycle through which functions names from the match above are linked to reversing and splicing
    NSArray *matches = [self matchesForString:x withRegex:@"([$_A-Za-z0-9]+):|reverse|splice"];
    int i = 0;
    
    /*
     adopted from the javascript version to identify the functions, probably not the most efficient way, but it works!
     Loop through the matches and if a != reverse | splice then set the value to tmp, the function names are listed
     prior to their purpose:
     
     ie: [Ww,splice,w9,reverse]
     
     splice = Ww; & reverse = W9;
     
     */
    
    for (i = 0; i < [matches count]; i++)
    {
        a = [matches objectAtIndex:i];
        if (r != nil && s != nil)
        {
            break;
        }
        if([a isEqualToString:@"reverse"])
        {
            r = tmp;
        } else if ([a isEqualToString:@"splice"])
        {
            s = tmp;
        } else {
            tmp = [a stringByReplacingOccurrencesOfString:@":" withString:@""];
        }
    }
    
    /*
     
     the new signature is made into a key array for easily moving characters around as needed based on the cipher
     ie cr.Ww(a,13);cr.W9(a,69);cr.Gz(a,3);cr.Ww(a,2);cr.W9(a,79);cr.Gz(a,3);cr.Ww(a,36);return a.join(
     
     broken up into chunks like
     
     cr.Ww(a,13)
     
     this will allow us to take the keyMatch string and actually determine when to reverse, splice or swap
     
     */
    NSMutableArray *keys = [NSMutableArray new];
    
    NSArray *keyMatches = [self matchesForString:keyMatch withRegex:@"[$_A-Za-z0-9]+\\.([$_A-Za-z0-9]+)\\(a,(\\d*)\\)"];
    for (NSString *theMatch in keyMatches)
    {
        //fr.Ww(a,13) split this up into something like Ww and 13
        NSString *importantSection = [[theMatch componentsSeparatedByString:@"."] lastObject];
        NSString *numberValue = [[[importantSection componentsSeparatedByString:@","] lastObject] stringByReplacingOccurrencesOfString:@")" withString:@""]; //13
        NSString *fnName = [[importantSection componentsSeparatedByString:@"("] objectAtIndex:0]; // Ww
        
        if ([fnName isEqualToString:r]) //reverse
        {
            [keys addObject:@"0"]; //0 in our signature key means reverse the string
        } else if ([fnName isEqualToString:s]) //if its the splice function store it as a negative value
        {
            [keys addObject:[NSString stringWithFormat:@"-%@", numberValue]];
        } else { //were not splicing or reversing, so its going to be a swap value
            [keys addObject:numberValue];
        }
    }
    
    //take the final key array and make it into something like 13,0,-3,2,0,-3,36
    
    self.ytkey = [keys componentsJoinedByString:@","];
    
    DLog(@"timestamp: %@", self.yttimestamp);
    DLog(@"selfytkey: %@", self.ytkey);
    
}


/**
 
 this function will take the key array and splice it from the starting index to the end of the string with the value 3
 would change:
 105105282D9AD56125199603D23E2C93F04C9D2237A.B8A82DC92F00EF86757325D88E778BC5D08FC252252 to
 105282D9AD56125199603D23E2C93F04C9D2237A.B8A82DC92F00EF86757325D88E778BC5D08FC252252
 
 */

- (NSMutableArray *)sliceArray:(NSArray *)theArray atIndex:(int)theIndex
{
    NSRange theRange = NSMakeRange(theIndex, theArray.count-theIndex);
    return [[theArray subarrayWithRange:theRange] mutableCopy];
}

/*
 
 take an array and reverse it, the mutable copy thing probably isnt very efficient but a necessary? evil to
 retain mutability
 
 */

- (NSMutableArray *)reversedArray:(NSArray *)theArray
{
    return [[[theArray reverseObjectEnumerator] allObjects] mutableCopy];
}

/*
 
 take the value at index 0 and swap it with theIndex
 
 */

- (NSMutableArray *)swapCharacterAtIndex:(int)theIndex inArray:(NSMutableArray *)theArray
{
    [theArray exchangeObjectAtIndex:0 withObjectAtIndex:theIndex];
    return theArray;
    
}



/*
 
 big encirido to decode the signature, takes a value like 13,0,-3,2,0,-3,36 and a signature
 and spits out usable version of it, only needed wheb use signature cipher is true
 
 */

- (NSString *)decodeSignature:(NSString *)theSig
{
    NSMutableArray *s = [[theSig splitString] mutableCopy];
    NSArray *keyArray = [self.ytkey componentsSeparatedByString:@","];
    int i = 0;
    for (i = 0; i < [keyArray count]; i++)
    {
        int n = [[keyArray objectAtIndex:i] intValue];
        if (n == 0) //reverse
        {
            s = [self reversedArray:s];
        } else if (n < 0) //slice
        {
            s = [self sliceArray:s atIndex:-n];
            
        } else {
            s = [self swapCharacterAtIndex:n inArray:s];
        }
    }
    return[s componentsJoinedByString:@""];
}


@end
