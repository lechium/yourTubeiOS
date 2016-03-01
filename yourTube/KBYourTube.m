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

/**
 
 out of pure laziness I put the implementation KBYTStream and KBYTMedia classes in this file and their interfaces
 in the header file. However, it does provide easier portability since I have yet to make this into a library/framework/pod
 
 
 */


@implementation YTKBPlayerViewController

/*
 
 most of the code in this class are the stupid hurdles to jump through to not roll your own AVPlayerView &
 & controller but to maintain playback in the background & then regain video in the foreground.
 
 adapted and fixed from http://stackoverflow.com/questions/31621618/remove-and-restore-avplayer-to-enable-background-video-playback/33240738#33240738
 
 
 */

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    //[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    MPRemoteCommandCenter *shared = [MPRemoteCommandCenter sharedCommandCenter];
    [shared.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        [[self player] pause];
        return MPRemoteCommandHandlerStatusSuccess;
        
    }];
    
    [shared.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        [[self player] play];
        return MPRemoteCommandHandlerStatusSuccess;
        
    }];
    
    [shared.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        
        NSArray *playerItems = [(AVQueuePlayer *)[self player] items];
        KBYTMedia *currentItem = [[playerItems firstObject] associatedMedia];
        [(AVQueuePlayer *)[self player] advanceToNextItem];
        playerItems = [(AVQueuePlayer *)[self player] items];
        currentItem = [[playerItems firstObject] associatedMedia];
        if (currentItem == nil) { return MPRemoteCommandHandlerStatusCommandFailed; }
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : currentItem.title, MPMediaItemPropertyPlaybackDuration: [NSNumber numberWithInteger:[[currentItem duration]timeFromDuration]] };
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    LOG_SELF;
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand removeTarget:self];
    [[MPRemoteCommandCenter sharedCommandCenter].playCommand removeTarget:self];
    [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand removeTarget:self];
    [(AVQueuePlayer *)[self player] removeAllItems];
    self.player = nil;
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    // [[self player] stop];
}

- (void)didForeground:(NSNotification *)n
{
    if (_playerToRestore != nil && _layerToRestore != nil)
    {
        [_layerToRestore setPlayer:_playerToRestore];
        _playerToRestore = nil;
        _layerToRestore = nil;
    }
}

- (AVPlayerLayer *)findPlayerView {
    return [self findLayerWithAVPlayerLayer:self.view];
}

- (AVPlayerLayer *)findLayerWithAVPlayerLayer:(UIView *)view {
    AVPlayerLayer *foundView = nil;
    @try {
        foundView = [view valueForKey:@"_videoLayer"];
    }
    @catch ( NSException *e ) {
        //  NSLog(@"exception: %@", e);
    }
    @finally
    {
        if (foundView != nil)
        {
            return foundView;
        }
    }
    for (UIView *v in view.subviews) {
        AVPlayerLayer *theLayer = [self findLayerWithAVPlayerLayer:v];
        if (theLayer != nil)
        {
            return theLayer;
        }
    }
    return nil;
}

- (BOOL)isPlaying
{
    if ([self player] != nil)
    {
        if (self.player.rate != 0)
        {
            return true;
        }
    }
    return false;
    
}

- (BOOL)hasVideo
{
    AVPlayerItem *playerItem = [[self player] currentItem];
    NSArray *tracks = [playerItem tracks];
    for (AVPlayerItemTrack *playerItemTrack in tracks)
    {
        // find video tracks
        if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicVisual])
        {
            NSLog(@"is video!");
            //playerItemTrack.enabled = NO; // disable the track
            return true;
        }
    }
    return false;
}

- (void)didBackground:(NSNotification *)n
{
    //NSString *recursiveDesc = [self.view performSelector:@selector(recursiveDescription)];
    // NSLog(@"view recursiveDescription: %@", recursiveDesc);
    if ([self isPlaying] == true && [self hasVideo] == true)
    {
        _layerToRestore = [self findPlayerView];
        _playerToRestore = [_layerToRestore player];
        [_layerToRestore setPlayer:nil];
        
    }
}

- (BOOL)shouldAutorotate
{
    return TRUE;
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
        case kYTSearchResultTypeUnknown: return @"Unknown";
        case kYTSearchResultTypeVideo: return @"Video";
        case kYTSearchResultTypePlaylist: return @"Playlist";
        case kYTSearchResultTypeChannel: return @"Channel";
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
    return @{@"title": self.title, @"author": self.author, @"details": self.details, @"imagePath": self.imagePath, @"videoId": self.videoId, @"duration": self.duration, @"age": self.age, @"views": self.views, @"resultType": [self readableSearchType]};
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
    return @{@"title": self.title, @"type": self.type, @"format": self.format, @"height": self.height, @"itag": [NSNumber numberWithInteger:self.itag], @"extension": self.extension, @"url": self.url, @"outputFilename": self.outputFilename};
}

- (NSString *)description
{
    return [[self dictionaryValue] description];
}


@end

@implementation YTPlayerItem

@synthesize associatedMedia;

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

- (NSDictionary *)dictionaryRepresentation
{
    if (self.details == nil)self.details = @"Unavailable";
    return @{@"title": self.title, @"author": self.author, @"keywords": self.keywords, @"videoID": self.videoId, @"views": self.views, @"duration": self.duration, @"images": self.images, @"streams": self.streams, @"details": self.details};
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
    NSLog(@"displayMessageString: %@", displayMessageString);
    NSString *checkString = @"Watch History isn't viewable when signed out.";
    if ([displayMessageString rangeOfString:checkString].location == NSNotFound || [displayMessageString length] == 0 || displayMessageString == nil)
    {
        return true;
    }
    return false;
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
            NSDictionary *returnDict = nil;
            if (signedIn == true) {
                
                NSDictionary *channelDict = [self channelIDAndWatchLaterCount];
              //  NSLog(@"channelDict: %@", channelDict);
                NSString *channelID = channelDict[@"channelID"];
                NSDictionary *ourUserDetails = [self userDetailsFromChannelURL:channelID];
                NSString *userName = ourUserDetails[@"username"];
                NSInteger channelVideoCount = [self videoCountForUserName:userName];
                //NSArray *playlists = [self playlistArrayFromUserName:userName];
                NSMutableArray *itemArray = [[NSMutableArray alloc] initWithArray:[self playlistArrayFromUserName:userName]];
                KBYTSearchResult *userChannel = [KBYTSearchResult new];
                userChannel.title = @"Your channel";
                userChannel.author = userName;
                userChannel.videoId = channelID;
                userChannel.details = [NSString stringWithFormat:@"%lu videos", channelVideoCount];
                userChannel.imagePath = ourUserDetails[@"profileImage"];
                userChannel.resultType = kYTSearchResultTypeChannel;
                [itemArray addObject:userChannel];
                
                KBYTSearchResult *wlPl = [KBYTSearchResult new];
                wlPl.author = userName;
                wlPl.videoId = @"WL";
                wlPl.details = [NSString stringWithFormat:@"%@ videos", channelDict[@"wlCount"]];
                wlPl.title = @"Watch later";
                wlPl.imagePath = ourUserDetails[@"profileImage"];
                wlPl.resultType = kYTSearchResultTypePlaylist;
                
                [itemArray addObject:wlPl];
                
                
                //NSArray *channelVideos = [self videoChannelsList:channelID][@"results"];
                
                returnDict = @{@"channelID": channelID, @"userName": userName, @"results": itemArray};
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
    NSArray *itemCounts = [(NSEnumerator *)[root XPath:@".//span[contains(@class, 'yt-valign-container guide-count-value')]"] allObjects];
    NSString *watchLaterCount = [[itemCounts objectAtIndex:1] stringValue];
    ONOXMLElement *guideSection = [root firstChildWithXPath:@"//li[contains(@class, 'guide-section')]"];
    NSArray *allObjects = [(NSEnumerator *)[guideSection XPath:@".//a[contains(@class, 'guide-item')]"] allObjects];
    if ([allObjects count] > 1)
    {
        ONOXMLElement *channelElement = [allObjects objectAtIndex:1];
        return @{@"channelID": [[channelElement valueForAttribute:@"href"] lastPathComponent], @"wlCount": watchLaterCount};
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

- (NSDictionary *)userDetailsFromChannelURL:(NSString *)channelURL
{
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/channel/%@", channelURL]];
    ONOXMLElement *root = [xmlDoct rootElement];
    ONOXMLElement *canon = [root firstChildWithXPath:@"//link[contains(@rel, 'canonical')]"];
    //<img class="channel-header-profile-image" src="//i.ytimg.com/i/iuFEQ2-YiaW97Uzu00bOZQ/mq1.jpg?v=564b8e92" title="nito" alt="nito">
    NSString *profileImage = [[root firstChildWithXPath:@"//img[contains(@class, 'channel-header-profile-image')]"] valueForAttribute:@"src"];
    
    
    return @{@"username": [[canon valueForAttribute:@"href"] lastPathComponent], @"profileImage": [NSString stringWithFormat:@"http:%@", profileImage] } ;
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
            result.imagePath = [@"https:" stringByAppendingString:imagePath];
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

- (NSArray *)playlistArrayFromUserName:(NSString *)userName
{
    ONOXMLDocument *xmlDoct = [self documentFromURL:[NSString stringWithFormat:@"https://m.youtube.com/%@/playlists", userName]];
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
        result.imagePath = [NSString stringWithFormat:@"https:%@", thumbPath];
        result.title = playlistTitle;
        result.author = userName;
        result.details = videoCount;
        result.videoId = playlistURL;
        result.resultType = kYTSearchResultTypePlaylist;
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

- (void)airplayStream:(NSString *)stream ToDeviceIP:(NSString *)deviceIP
{
    [[KBYTMessagingCenter sharedInstance] airplayStream:stream ToDeviceIP:deviceIP];
    
}

//take a url and get its raw body, then return in string format

- (NSString *)stringFromRequest:(NSString *)url
{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:10];
    
    NSURLResponse *response = nil;
    
    [request setHTTPMethod:@"GET"];
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

- (void)getPlaylistVideos:(NSString *)listID
          completionBlock:(void(^)(NSDictionary  * playlistDetails))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            NSString *requestString = [NSString stringWithFormat:@"https://www.youtube.com/playlist?list=%@", listID];
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
            ONOXMLElement *root = [xmlDoc rootElement];
            //NSLog(@"root element: %@", root);
            
            ONOXMLElement *videosElement = [root firstChildWithXPath:@"//*[contains(@class, 'pl-video-list')]"];
            id videoEnum = [videosElement XPath:@".//*[contains(@class, 'pl-video')]"];
            ONOXMLElement *currentElement = nil;
            NSMutableArray *finalArray = [NSMutableArray new];
            NSMutableDictionary *outputDict = [NSMutableDictionary new];
            NSInteger i = 0;
            ONOXMLElement *playlistDetails = [root firstChildWithXPath:@"//*[contains(@class, 'pl-header-details')]"];
            
            for (ONOXMLElement *detailChild in [playlistDetails children])
            {
                switch (i) {
                    case 0:
                        outputDict[@"playlistAuthor"] = [detailChild stringValue];
                        break;
                        
                    case 1:
                        outputDict[@"totalCount"] = [[[detailChild stringValue] componentsSeparatedByString:@" "] firstObject];
                        break;
                        
                    case 2:
                        outputDict[@"views"] = [detailChild stringValue];
                        break;
                        
                    case 3:
                        outputDict[@"lastUpdated"] = [detailChild stringValue];
                        break;
                        
                    default:
                        break;
                }
                i++;
            }
            
            while (currentElement = [videoEnum nextObject])
            {
                KBYTSearchResult *result = [KBYTSearchResult new];
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
                    result.imagePath = [@"https:" stringByAppendingString:imagePath];
                }
                if (lengthElement != nil)
                    result.duration = [lengthElement.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                if (authorElement != nil)
                {
                    result.author = [authorElement stringValue];
                }
                
                if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"] && ![result.title isEqualToString:@"[Deleted Video]"]&& ![result.title isEqualToString:@"[Private Video]"])
                {
                    //NSLog(@"result: %@", result);
                    [finalArray addObject:result];
                } else {
                    result = nil;
                }
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([finalArray count] > 0)
                {
                    completionBlock(outputDict);
                } else {
                    failureBlock([NSString stringWithFormat:@"failed to fetch playlist information for playlist id: %@",listID]);
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
                result.resultType = kYTSearchResultTypeVideo;
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
                    result.imagePath = [@"https:" stringByAppendingString:imagePath];
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
                result.resultType = kYTSearchResultTypeVideo;
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
                    result.imagePath = [@"https:" stringByAppendingString:imagePath];
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

- (void)getChannelVideos:(NSString *)channelID
         completionBlock:(void(^)(NSDictionary *searchDetails))completionBlock
            failureBlock:(void(^)(NSString *error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
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
                    result.imagePath = [@"https:" stringByAppendingString:imagePath];
                }
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
                result.resultType = kYTSearchResultTypeVideo;
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
                    result.imagePath = [@"https:" stringByAppendingString:imagePath];
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

/**
 
 did some massive refactoring here, added mattt's epic Ono XML parsing library that is based
 on libxml2. the speed of the search seems to be pretty much identical, however, the scraping
 is much more elegant using various XPath queries rather than finding search results by using
 massive hacks on delimiting items that was done in the old search version
 
 */

- (void)youTubeSearch:(NSString *)searchQuery
           pageNumber:(NSInteger)page
    includeAllResults:(BOOL)includeAll
      completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
         failureBlock:(void(^)(NSString* error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            //handle pagination
            
            NSString *pageorsm = nil;
            if (page == 1)
            {
                pageorsm = @"sm=1";
            } else {
                pageorsm = [NSString stringWithFormat:@"page=%lu", page];
            }
            
            NSString *requestString = nil;
            
            if (includeAll == false)
            {
                requestString = [NSString stringWithFormat:@"https://m.youtube.com/results?%@&q=%@&%@", @"sp=EgIQAQ%253D%253D", [searchQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pageorsm];
            } else {
                requestString = [NSString stringWithFormat:@"https://m.youtube.com/results?search_query=%@&%@",  [searchQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pageorsm];
            }
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            ONOXMLDocument *xmlDoc = [ONOXMLDocument HTMLDocumentWithString:rawRequestResult encoding:NSUTF8StringEncoding error:nil];
            ONOXMLElement *root = [xmlDoc rootElement];
            //scan down to the section-list to find the videos
            NSString *fullSectionXPath = @"//ol[contains(@class, 'section-list')]";
            ONOXMLElement *sectionListElement = [root firstChildWithXPath:fullSectionXPath];
            //get the search result number
            ONOXMLElement *numListElement = [sectionListElement firstChildWithXPath:@"//p[contains(@class,'num-results')]"];
            NSInteger results = 0;
            if (numListElement !=nil)
            {
                NSString *resultText = [numListElement stringValue];
                results = [[[[[resultText componentsSeparatedByString:@"About"] lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"," withString:@""] integerValue];
            }
            //find the element inside the section list that has all our video details inside
            ONOXMLElement *videosElement = [sectionListElement firstChildWithXPath:@".//ol[contains(@class, 'item-section')]"];
            
            //yt-lockup-video is currently the common denominator for every video div, this is
            //a potential weak point if youtube changes these variable names one day.
            id videoEnum = [videosElement XPath:@"//div[contains(@class, 'yt-lockup-video')]"];
            ONOXMLElement *videoDetailXMLRepresentation = nil;
            NSMutableArray *finalArray = [NSMutableArray new];
            NSMutableDictionary *outputDict = [NSMutableDictionary new];
            outputDict[@"resultCount"] = [NSNumber numberWithInteger:results];
            while (videoDetailXMLRepresentation = [videoEnum nextObject])
            {
                KBYTSearchResult *result = [KBYTSearchResult new];
                NSString *videoID = [videoDetailXMLRepresentation valueForAttribute:@"data-context-item-id"];
                if (videoID != nil)
                {
                    result.videoId = videoID;
                }
                ONOXMLElement *thumbNailElement = [[[videoDetailXMLRepresentation firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-simple')]"] children] firstObject];
                ONOXMLElement *lengthElement = [videoDetailXMLRepresentation firstChildWithXPath:@".//*[contains(@class, 'video-time')]"];
                ONOXMLElement *titleElement = [videoDetailXMLRepresentation firstChildWithXPath:@".//*[contains(@class, 'yt-uix-tile-link')]"];
                ;
                ONOXMLElement *descElement = [videoDetailXMLRepresentation firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-description')]"];
                ONOXMLElement *authorElement = [[[videoDetailXMLRepresentation firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-byline')]"] children] firstObject];
                ONOXMLElement *ageAndViewsElement = [videoDetailXMLRepresentation firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-meta-info')]"];
                
                result.resultType = kYTSearchResultTypeVideo;
                
                NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                if (imagePath == nil)
                {
                    imagePath = [thumbNailElement valueForAttribute:@"src"];
                }
                if (imagePath != nil)
                {
                    result.imagePath = [@"https:" stringByAppendingString:imagePath];
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
                //filter out anything that isnt a video, and filter out all the ads
                if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
                {
                    //NSLog(@"result: %@", result);
                    [finalArray addObject:result];
                } else {
                    result = nil;
                }
                if ([finalArray count] > 0)
                {
                    outputDict[@"results"] = finalArray;
                    NSInteger pageCount = results/[finalArray count];
                    outputDict[@"pageCount"] = [NSNumber numberWithInteger:pageCount];
                }
            }
            
            if (includeAll == true) //find playlists and channels too
            {
                //yt-lockup-playlist
                ONOXMLElement *currentElement = nil;
                id plEnum = [videosElement XPath:@"//div[contains(@class, 'yt-lockup-playlist')]"];
                NSMutableArray *playlistArray = [NSMutableArray new];
                while (currentElement = [plEnum nextObject])
                {
                    //  NSLog(@"plelement: %@", currentElement);
                    KBYTSearchResult *result = [KBYTSearchResult new];
                    
                    ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-simple')]"] children] firstObject];
                    ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-uix-tile-link')]"];
                    ONOXMLElement *authorElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-byline')]"] children] firstObject];
                    ONOXMLElement *descElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-meta-info')]"] children] firstObject];//yt-lockup-meta-info
                    
                    ONOXMLElement *plIdElement = [currentElement firstChildWithXPath:@".//li[contains(@role, 'menuitem')]"];
                    
                    result.resultType = kYTSearchResultTypePlaylist;
                    
                    NSString *videoID = [plIdElement valueForAttribute:@"data-list-id"];
                    if (videoID != nil)
                    {
                        result.videoId = videoID;
                    }
                    NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                    if (imagePath == nil)
                    {
                        imagePath = [thumbNailElement valueForAttribute:@"src"];
                    }
                    if (imagePath != nil)
                    {
                        result.imagePath = [@"https:" stringByAppendingString:imagePath];
                    }
                    if (titleElement != nil)
                        result.title = [[titleElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    
                    if (authorElement != nil)
                    {
                        result.author = [authorElement stringValue];
                    }
                    if (descElement != nil)
                    {
                        result.details = [descElement stringValue];
                    }
                    
                    if ([result.videoId length] > 0)
                    {
                        [playlistArray addObject:result];
                    }
                }
                
                if ([playlistArray count] > 0)
                {
                    [finalArray addObjectsFromArray:playlistArray];
                    outputDict[@"results"] = finalArray;
                    //outputDict[@"playlists"] = playlistArray;
                }
                
                //yt-lockup-channel
                id channelEnum = [videosElement XPath:@"//div[contains(@class, 'yt-lockup-channel')]"];
                NSMutableArray *channelArray = [NSMutableArray new];
                while (currentElement = [channelEnum nextObject])
                {
                    //   NSLog(@"channelelement: %@", currentElement);
                    KBYTSearchResult *result = [KBYTSearchResult new];
                    
                    ONOXMLElement *channelIDElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-thumbnail')]"] children] firstObject];
                    
                    NSString *videoID = [channelIDElement valueForAttribute:@"data-ytid"];
                    if (videoID != nil)
                    {
                        result.videoId = videoID;
                    }
                    ONOXMLElement *thumbNailElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-thumb-simple')]"] children] firstObject];
                    ONOXMLElement *titleElement = [currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-uix-tile-link')]"];
                    ONOXMLElement *authorElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-byline')]"] children] firstObject];
                    ONOXMLElement *descElement = [[[currentElement firstChildWithXPath:@".//*[contains(@class, 'yt-lockup-meta-info')]"] children] lastObject];//yt-lockup-meta-info
                    
                    result.resultType = kYTSearchResultTypeChannel;
                    
                    NSString *imagePath = [thumbNailElement valueForAttribute:@"data-thumb"];
                    if (imagePath == nil)
                    {
                        imagePath = [thumbNailElement valueForAttribute:@"src"];
                    }
                    if (imagePath != nil)
                    {
                        result.imagePath = imagePath;
                    }
                    if (titleElement != nil)
                        result.title = [[titleElement stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    
                    if (authorElement != nil)
                    {
                        result.author = [authorElement stringValue];
                    }
                    if (descElement != nil)
                    {
                        result.details = [descElement stringValue];
                    }
                    
                    if ([result.videoId length] > 0)
                    {
                        [channelArray addObject:result];
                    }
                }
                
                if ([channelArray count] > 0)
                {
                    [finalArray addObjectsFromArray:channelArray];
                    outputDict[@"results"] = finalArray;
                    //outputDict[@"channels"] = channelArray;
                }
                
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([finalArray count] > 0)
                {
                    completionBlock(outputDict);
                } else {
                    failureBlock(@"fail");
                }
            });
        }
    });
    
}


/*
 
 This method is much tidier now with some recursive magic added to APElement, it is still potentially
 pretty fragile if google goes and changes class names on us, but it should be /less/ fragile then
 its short lived predecessor.
 
 */

- (void)ogYouTubeSearch:(NSString *)searchQuery
             pageNumber:(NSInteger)page
        completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
           failureBlock:(void(^)(NSString* error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            //handle pagination
            
            NSString *pageorsm = nil;
            if (page == 1)
            {
                pageorsm = @"sm=1";
            } else {
                pageorsm = [NSString stringWithFormat:@"page=%lu", page];
            }
            //@"sp=EgIQAQ%253D%253D" is added to limit searches to just videos, channels and playlists arent parsed...yet?
            NSString *requestString = [NSString stringWithFormat:@"https://m.youtube.com/results?%@&q=%@&%@", @"sp=EgIQAQ%253D%253D", [searchQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], pageorsm];
            NSString *rawRequestResult = [self stringFromRequest:requestString];
            
            //get the result number (i hate that two full scans are done to find this..)
            
            NSInteger results = [self resultNumber:rawRequestResult];
            
            //get the raw value we work with
            
            NSString *rawSearchValue = [self rawYTFromHTML:rawRequestResult];
            
            //NSLog(@"rawSearchValue: %@", rawSearchValue);
            
            //hard to find a delimiter that sticks out between results, </div></div></div></div></div></li> will have to do
            
            NSArray *videoArray = [rawSearchValue componentsSeparatedByString:@"<li><div class=\"yt-lockup yt-lockup-tile yt-lockup-video vve-check clearfix\""];
            
            /*
             NSArray *videoArray = [rawSearchValue componentsSeparatedByString:@"</div></div></div></div></div></li>"];
             if (([videoArray count] == 1 || [videoArray count] == 0) && results > 1)
             {
             videoArray = [rawSearchValue componentsSeparatedByString:@"</div></div></div></div></li>"];
             }
             */
            //create the array that will store the final results
            NSMutableDictionary *outputDict = [NSMutableDictionary new];
            outputDict[@"resultCount"] = [NSNumber numberWithInteger:results];
            NSMutableArray *finalArray = [NSMutableArray new];
            for (NSString *rawVideoInfo in videoArray)
            {
                //create a KBYTSearchResult for each result
                KBYTSearchResult *result = [KBYTSearchResult new];
                
                //add the delimiter back in so APXML can parse things properly
                // NSString *fullRawVideoInfo = [rawVideoInfo stringByAppendingString:@"</div></div></div></div></div></li>"];
                NSString *fullRawVideoInfo = [@"<li><div class=\"yt-lockup yt-lockup-tile yt-lockup-video vve-check clearfix\"" stringByAppendingString:rawVideoInfo];
                
                //this makes parsing the info a little less painful, treat it like XML with APDocument
                APDocument *videoDetailXMLRepresentation = [[APDocument alloc] initWithString:fullRawVideoInfo];
                
                //get all the necessary elements we will need to get our data
                
                APElement *rootElement = [videoDetailXMLRepresentation rootElement];
                APElement *thumbnailElement = [[rootElement elementContainingClassString:@"yt-thumb-simple"] firstChildElement];
                APElement *lengthElement = [rootElement elementContainingClassString:@"video-time"];
                APElement *titleElement = [rootElement elementContainingClassString:@"yt-uix-tile-link"];
                APElement *ageAndViewsElement = [rootElement elementContainingClassString:@"yt-lockup-meta-info"];
                APElement *authorElement = [[rootElement elementContainingClassString:@"yt-lockup-byline"] firstChildElement];
                APElement *descriptionElement = [rootElement elementContainingClassString:@"yt-lockup-description"];
                
                result.videoId  = [rootElement recursiveAttributeNamed:@"data-context-item-id"];
                
                //we have all of our elements now start grabbing the necessary data
                
                //for the thumbnail image sometimes its data-thumb, sometimes its src
                NSString *imagePath = [thumbnailElement valueForAttributeNamed:@"data-thumb"];
                if (imagePath == nil)
                {
                    imagePath = [thumbnailElement valueForAttributeNamed:@"src"];
                }
                if (imagePath != nil)
                {
                    result.imagePath = [@"https:" stringByAppendingString:imagePath];
                }
                
                //set the title and duration
                result.duration = lengthElement.value;
                result.title = [[titleElement value] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                
                /**
                 
                 both age and views are child nodes of ageAndViewsElement
                 <li>5 days ago</li>
                 <li>24,668 views</li>
                 
                 **/
                for (APElement *currentElement in [ageAndViewsElement childElements])
                {
                    NSString *currentValue = [currentElement value];
                    if ([currentValue containsString:@"ago"]) //age
                    {
                        result.age = currentValue;
                    } else if ([currentValue containsString:@"views"])
                    {
                        result.views = [[currentValue componentsSeparatedByString:@" "] firstObject];
                    }
                }
                
                result.author = [authorElement value];
                
                NSString *vdesc = [[descriptionElement value] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                if (vdesc != nil)
                {
                    result.details = [vdesc stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
                
                //done setting data, hopefully everything is good to go!
                
                // NSLog(@"result: %@", result);
                
                //if we got keys we got a result, add it to the array
                if (result.videoId.length > 0 && ![[[result author] lowercaseString] isEqualToString:@"ad"])
                    //if (result.title.length > 0)
                {
                    [finalArray addObject:result];
                } else {
                    result = nil;
                }
            }
            //doneski!
            if ([finalArray count] > 0)
            {
                outputDict[@"results"] = finalArray;
                NSInteger pageCount = results/[finalArray count];
                outputDict[@"pageCount"] = [NSNumber numberWithInteger:pageCount];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([finalArray count] > 0)
                {
                    completionBlock(outputDict);
                } else {
                    failureBlock(@"fail");
                }
            });
        }
    });
    
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
                self.yttimestamp = @"16806";
                self.ytkey = @"-1,0,65,-3,0";
                
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


- (void)getVideoDetailsForID:(NSString*)videoID
             completionBlock:(void(^)(KBYTMedia* videoDetails))completionBlock
                failureBlock:(void(^)(NSString* error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            KBYTMedia *rootInfo = nil;
            NSString *errorString = nil;
            
            //if we already have the timestamp and key theres no reason to fetch them again, should make additional calls quicker.
            if (self.yttimestamp.length == 0 && self.ytkey.length == 0)
            {
                //get the time stamp and cipher key in case we need to decode the signature.
                [self getTimeStampAndKey:videoID];
            }
            
            //a fallback just in case the jsbody is changed and we cant automatically grab current signatures
            //old ciphers generally continue to work at least temporarily.
            
            if (self.yttimestamp.length == 0 || self.ytkey.length == 0)
            {
                errorString = @"Failed to decode signature cipher javascript.";
                self.yttimestamp = @"16856";
                self.ytkey = @"44,49,0";
                
            }
            
            //the url we use to call get_video_info
            
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
                    rootInfo = [[KBYTMedia alloc] initWithDictionary:vars];
                } else {
                    
                    errorString = [[[vars objectForKey:@"reason"] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];
                    NSLog(@"get_video_info for %@ failed for reason: %@", videoID, errorString);
                    
                }
            } else {
                
                errorString = @"get_video_info failed.";
                
            }
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

- (void)getVideoDetailsForSearchResults:(NSArray*)searchResults
                        completionBlock:(void(^)(NSArray* videoArray))completionBlock
                           failureBlock:(void(^)(NSString* error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSMutableArray *finalArray = [NSMutableArray new];
            //NSMutableDictionary *rootInfo = [NSMutableDictionary new];
            NSString *errorString = nil;
            
            //if we already have the timestamp and key theres no reason to fetch them again, should make additional calls quicker.
            if (self.yttimestamp.length == 0 && self.ytkey.length == 0)
            {
                //get the time stamp and cipher key in case we need to decode the signature.
                [self getTimeStampAndKey:[[searchResults firstObject] videoId]];
            }
            
            //a fallback just in case the jsbody is changed and we cant automatically grab current signatures
            //old ciphers generally continue to work at least temporarily.
            
            if (self.yttimestamp.length == 0 || self.ytkey.length == 0)
            {
                errorString = @"Failed to decode signature cipher javascript.";
                self.yttimestamp = @"16856";
                self.ytkey = @"44,49,0";
                
            }
            
            //the url we use to call get_video_info
            
            NSInteger i = 0;
            
            for (KBYTSearchResult *result in searchResults) {
                //    NSLog(@"processing videoID %@ at index: %lu", result.videoId, i);
                
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
                self.yttimestamp = @"16856";
                self.ytkey = @"44,49,0";
                
            }
            
            //the url we use to call get_video_info
            
            NSInteger i = 0;
            
            for (NSString *videoID in videoIDs) {
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
    NSDictionary *info = @{@"filePath": theFile, @"duration": [NSNumber numberWithInteger:duration]};
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.importscience"];
    [center sendMessageName:@"org.nito.importscience.import" userInfo:info];
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
    
    NSString *baseJS = [NSString stringWithFormat:@"https:%@", [[[[[self matchesForString:body withRegex:@"\"js\":\"([^\"]*)\""] lastObject] componentsSeparatedByString:@":"] lastObject] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"]];
    
    //get the raw js source of the decoder file that we need to get the signature cipher from
    
    NSString *jsBody = [self stringFromRequest:[baseJS stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
    
    //crazy convoluted regex to get a signature section similiar to this
    //cr.Ww(a,13);cr.W9(a,69);cr.Gz(a,3);cr.Ww(a,2);cr.W9(a,79);cr.Gz(a,3);cr.Ww(a,36);return a.join(
    
    //#### IGNORE THE WARNING, if the extra escape is added as expected the regex doesnt work!
    
    NSString *keyMatch = [[self matchesForString:jsBody withRegex:@"function[ $_A-Za-z0-9]*\\(a\\)\\{a=a(?:\.split|\\[[$_A-Za-z0-9]+\\])\\(\"\"\\);\\s*([^\"]*)"] lastObject];
    
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
