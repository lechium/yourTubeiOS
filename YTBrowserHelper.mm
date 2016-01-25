//
//  YTBrowserHelper.mm
//  YTBrowserHelper
//
//  Created by Kevin Bradley on 12/30/15.
//  Copyright © 2015 nito. All rights reserved.
//

#import "YTBrowserHelper.h"
#import "ipodimport.h"
#import <Foundation/Foundation.h>
#import "AppSupport/CPDistributedMessagingCenter.h"

#import <CFNetwork/CFHTTPStream.h>

#import <arpa/inet.h>
#import <ifaddrs.h>

const NSUInteger    kAHVideo = 0,
kAHPhoto = 1,
kAHVideoFairPlay = 2,
kAHVideoVolumeControl = 3,
kAHVideoHTTPLiveStreams = 4,
kAHSlideshow = 5,
kAHScreen = 7,
kAHScreenRotate = 8,
kAHAudio = 9,
kAHAudioRedundant = 11,
kAHFPSAPv2pt5_AES_GCM = 12,
kAHPhotoCaching = 13;
const NSUInteger    kAHRequestTagReverse = 1,
kAHRequestTagPlay = 2;
const NSUInteger    kAHPropertyRequestPlaybackAccess = 1,
kAHPropertyRequestPlaybackError = 2,
kAHHeartBeatTag = 10;


const NSUInteger kAHAirplayStatusOffline = 0,
kAHAirplayStatusPlaying = 1,
kAHAirplayStatusPaused= 2;

@interface NSString (TSSAdditions)
- (id)dictionaryValue;
@end

@implementation NSString (TSSAdditions)


- (id)dictionaryValue
{
    NSString *error = nil;
    NSPropertyListFormat format;
    NSData *theData = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    id theDict = [NSPropertyListSerialization propertyListFromData:theData
                                                  mutabilityOption:NSPropertyListImmutable
                                                            format:&format
                                                  errorDescription:&error];
    return theDict;
}


@end

@interface JOiTunesImportHelper : NSObject

+ (_Bool)importAudioFileAtPath:(id)arg1 mediaKind:(id)arg2 withMetadata:(id)arg3 serverURL:(id)arg4;
+ (id)downloadManager;

@end

@implementation YTBrowserHelper

@synthesize airplaying, airplayTimer, deviceIP, sessionID, airplayDictionary;

//@synthesize webServer;
/*
 - (void)testRunServer
 {
 self.webServer = [[GCDWebServer alloc] init];
 [self.webServer addGETHandlerForBasePath:@"/" directoryPath:@"/var/mobile/Media/Downloads/" indexFilename:nil cacheAge:0 allowRangeRequests:YES];
 
 if ([self.webServer startWithPort:57287 bonjourName:@""]) {
 
 NSLog(@"started web server on port: %i", self.webServer.port);
 }
 }
 */


+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static YTBrowserHelper *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            shared = [YTBrowserHelper new];
            shared.prevInfoRequest = @"/scrub";
            shared.operationQueue = [NSOperationQueue mainQueue];
            shared.operationQueue.name = @"Connection Queue";
            shared.airplaying = NO;
            shared.paused = YES;
            shared.playbackPosition = 0;
        });
    }
    
    return shared;
    
}

- (void)startGCDWebServer {} //keep the compiler happy

/* 
 
 the music import process is needlessly convoluted to "protect" us, SSDownloads can't be triggered via local files
 JODebox runs a server the open source project GCDWebServer, im pretty sure all it does is just host files from
 /var/mobile/Media/Downloads after preparing them to be compatible to keep SSDownloadManager queues happy in thinking
 the file is coming from a remote source.

 */

//this method is never actually called inside YTBrowserHelper, we hook into -(id)init in SpringBoard and add this
//method in YTBrowser.xm

- (NSDictionary *)handleMessageName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    
    if ([[name pathExtension] isEqualToString:@"import"])
    {
        [self startGCDWebServer]; //start the GCDServer before we kick off the import.
        
        //right now the userInfo dict only has a filePath and a duration of the input file
        //remember this is being called from inside SpringBoard and not YTBrowserHelper, so this is how we pass the
        //information to our JODebox wrapper.
        [[YTBrowserHelper sharedInstance] importFileWithJO:userInfo[@"filePath"] duration:userInfo[@"duration"]];
        return nil;
    } else if ([[name pathExtension] isEqualToString:@"startAirplay"])
    {
        [[YTBrowserHelper sharedInstance] startAirplayFromDictionary:userInfo];
        
       return nil;
    }else if ([[name pathExtension] isEqualToString:@"pauseAirplay"])
    {
        [[YTBrowserHelper sharedInstance] togglePaused];
         return nil;
    } else if ([[name pathExtension] isEqualToString:@"stopAirplay"])
    {
        [[YTBrowserHelper sharedInstance] stopPlayback];
         return nil;
    } else if ([[name pathExtension] isEqualToString:@"airplayState"])
    {
        return [[YTBrowserHelper sharedInstance] airplayState];
   
    } else if ([[name pathExtension] isEqualToString:@"airplayInfo"])
    
     return nil;
}


- (void)startAirplayFromDictionary:(NSDictionary *)airplayDict
{
    CFUUIDRef UUID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDString = CFUUIDCreateString(kCFAllocatorDefault,UUID);
    self.sessionID = (__bridge NSString *)UUIDString;
    self.deviceIP = airplayDict[@"deviceIP"];
    NSString *address = [NSString stringWithFormat:@"http://%@", airplayDict[@"deviceIP"]];
    self.baseUrl = [NSURL URLWithString:address];
    [self playRequest:airplayDict[@"videoURL"]];
}

- (void)playRequest:(NSString *)httpFilePath
{
    NSDictionary        *plist = nil;
    NSString            *errDesc = nil;
    NSString            *appName = nil;
    NSError             *error = nil;
    NSData              *outData = nil;
    NSString            *dataLength = nil;
    CFURLRef            myURL;
    CFStringRef         bodyString;
    CFStringRef         requestMethod;
    CFHTTPMessageRef    myRequest;
    CFDataRef           mySerializedRequest;
    
    NSLog(@"/play");
    
    appName = @"MediaControl/1.0";
    
    plist = @{ @"Content-Location" : httpFilePath,
               @"Start-Position" : @0.0f };
    
    outData = [NSPropertyListSerialization dataFromPropertyList:plist
                                                         format:NSPropertyListBinaryFormat_v1_0
                                               errorDescription:&errDesc];
    
    if (outData == nil && errDesc != nil) {
        NSLog(@"Error creating /play info plist: %@", errDesc);
        return;
    }
    
    dataLength = [NSString stringWithFormat:@"%lu", [outData length]];
    
    bodyString = CFSTR("");
    requestMethod = CFSTR("POST");
    myURL = (__bridge CFURLRef)[self.baseUrl URLByAppendingPathComponent:@"play"];
    myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod,
                                           myURL, kCFHTTPVersion1_1);
    
    CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("User-Agent"),
                                     (__bridge CFStringRef)appName);
    CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Length"),
                                     (__bridge CFStringRef)dataLength);
    CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Type"),
                                     CFSTR("application/x-apple-binary-plist"));
    CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Apple-Session-ID"),
                                     (__bridge CFStringRef)self.sessionID);
    mySerializedRequest = CFHTTPMessageCopySerializedMessage(myRequest);
    self.data = [(__bridge NSData *)mySerializedRequest mutableCopy];
    [self.data appendData:outData];
    self.mainSocket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                 delegateQueue:dispatch_get_main_queue()];
    
    NSArray *ipArray = [deviceIP componentsSeparatedByString:@":"];
    NSError *connectError = nil;
    
     [self.mainSocket connectToHost:[ipArray firstObject] onPort:[[ipArray lastObject] integerValue] error:&connectError];
    
    if (connectError != nil)
    {
        NSLog(@"connection error: %@", [connectError localizedDescription]);
    }
    
    if (self.mainSocket != nil) {
        [self.mainSocket writeData:self.data
                       withTimeout:1.0f
                               tag:kAHRequestTagPlay];
        [self.mainSocket readDataToData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]
                            withTimeout:15.0f
                                    tag:kAHRequestTagPlay];
    } else {
        NSLog(@"Error connecting socket for /play: %@", error);
    }
}

- (void)setCommonHeadersForRequest:(NSMutableURLRequest *)request
{
    [request addValue:@"MediaControl/1.0" forHTTPHeaderField:@"User-Agent"];
    [request addValue:self.sessionID forHTTPHeaderField:@"X-Apple-Session-ID"];
}

- (NSDictionary *)synchronousPlaybackInfo
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/playback-info"
                                                                              relativeToURL:self.baseUrl]];
    [request addValue:@"MediaControl/1.0" forHTTPHeaderField:@"User-Agent"];
    NSURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    NSLog(@"return details: %@", datString);
    return [datString dictionaryValue];
}



//  alternates /scrub and /playback-info
- (void)infoRequest
{
    [self writeOK];
    NSString                *nextRequest = @"/playback-info";
    NSMutableURLRequest     *request = nil;
    
    if (self.airplaying) {
        if ([self.prevInfoRequest isEqualToString:@"/playback-info"]) {
            nextRequest = @"/scrub";
            self.prevInfoRequest = @"/scrub";
            
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:nextRequest
                                                                 relativeToURL:self.baseUrl]];
            [self setCommonHeadersForRequest:request];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:self.operationQueue
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       //  update our position in the file after /scrub
                                       NSString    *responseString = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
                                       NSRange     cachedDurationRange = [responseString rangeOfString:@"position: "];
                                       NSUInteger  cachedDurationEnd;
                                       
                                       if (cachedDurationRange.location != NSNotFound) {
                                           cachedDurationEnd = cachedDurationRange.location + cachedDurationRange.length;
                                           self.playbackPosition = [[responseString substringFromIndex:cachedDurationEnd] doubleValue];
                                           //[self.delegate positionUpdated:self.playbackPosition];
                                       }
                                   }];
        } else {
            nextRequest = @"/playback-info";
            self.prevInfoRequest = @"/playback-info";
            
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:nextRequest
                                                                 relativeToURL:self.baseUrl]];
            [self setCommonHeadersForRequest:request];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:self.operationQueue
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       //  update our playback status and position after /playback-info
                                       NSDictionary            *playbackInfo = nil;
                                       NSString                *errDesc = nil;
                                       NSNumber                *readyToPlay = nil;
                                       NSPropertyListFormat    format;
                                       
                                       if (!self.airplaying) {
                                           return;
                                       }
                                       
                                       playbackInfo = [NSPropertyListSerialization propertyListFromData:data
                                                                                       mutabilityOption:NSPropertyListImmutable
                                                                                                 format:&format
                                                                                       errorDescription:&errDesc];
                                       
                                     //  NSLog(@"playbackInfo: %@", playbackInfo );
                                       
                                       if ([[playbackInfo allKeys] count] == 0 || playbackInfo == nil)
                                       {
                                           [self stopPlayback];
                                           
                                       }
                                       
                                       if ((readyToPlay = [playbackInfo objectForKey:@"readyToPlay"])
                                           && ([readyToPlay boolValue] == NO)) {
                                           NSDictionary    *userInfo = nil;
                                           NSString        *bundleIdentifier = nil;
                                           NSError         *error = nil;
                                           
                                           userInfo = @{ NSLocalizedDescriptionKey : @"Target AirPlay server not ready.  "
                                                         "Check if it is on and idle." };
                                           
                                           bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
                                           error = [NSError errorWithDomain:bundleIdentifier
                                                                       code:100
                                                                   userInfo:userInfo];
                                           
                                           NSLog(@"Error: %@", [error description]);
                                             [self stoppedWithError:error];
                                       } else if ([playbackInfo objectForKey:@"position"]) {
                                           self.playbackPosition = [[playbackInfo objectForKey:@"position"] doubleValue];
                                           self.paused = [[playbackInfo objectForKey:@"rate"] doubleValue] < 0.5f ? YES : NO;
                                           
                                           //[self.delegate setPaused:self.paused];
                                           //[self.delegate positionUpdated:self.playbackPosition];
                                       } else if (playbackInfo != nil) {
                                           [self getPropertyRequest:kAHPropertyRequestPlaybackError];
                                       } else {
                                           NSLog(@"Error parsing /playback-info response: %@", errDesc);
                                       }
                                   }];
        }
    }
}

- (void)togglePaused
{
    if (self.airplaying) {
        self.paused = !self.paused;
        [self changePlaybackStatus];
    }
}

- (void)getPropertyRequest:(NSUInteger)property
{
    NSMutableURLRequest *request = nil;
    NSString *reqType = nil;
    NSString *urlString = @"/getProperty?%@";
    if (property == kAHPropertyRequestPlaybackAccess) {
        reqType = @"playbackAccessLog";
    } else {
        reqType = @"playbackErrorLog";
    }
    
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:urlString, reqType]
                                                         relativeToURL:self.baseUrl]];
    
    [self setCommonHeadersForRequest:request];
    [request setValue:@"application/x-apple-binary-plist" forHTTPHeaderField:@"Content-Type"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               //  get the PLIST from the response and log it
                               NSDictionary            *propertyPlist = nil;
                               NSString                *errDesc = nil;
                               NSPropertyListFormat    format;
                               
                               propertyPlist = [NSPropertyListSerialization propertyListFromData:data
                                                                                mutabilityOption:NSPropertyListImmutable
                                                                                          format:&format
                                                                                errorDescription:&errDesc];
                               
                               [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                   NSLog(@"%@: %@", reqType, propertyPlist);
                               }];
                           }];
}

- (void)stopRequest
{
    NSMutableURLRequest *request = nil;
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/stop"
                                                         relativeToURL:self.baseUrl]];
    
    [self setCommonHeadersForRequest:request];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [self stoppedWithError:nil];
                               [self.mainSocket disconnectAfterReadingAndWriting];
                           }];
}

- (NSDictionary *)airplayState
{
    if (self.mainSocket == nil || [self.mainSocket isDisconnected] == true) {
        return @{@"playbackState": [NSNumber numberWithUnsignedInteger:kAHAirplayStatusOffline]};
    }
    
    if (airplaying && self.paused)
    {
        return @{@"playbackState": [NSNumber numberWithUnsignedInteger:kAHAirplayStatusPaused]};
    }
    if (airplaying && !self.paused)
    {
        return @{@"playbackState": [NSNumber numberWithUnsignedInteger:kAHAirplayStatusPlaying]};
    }
}

- (void)stopPlayback
{
    NSLog(@"stop playback");
    if (self.airplaying) {
        [self stopRequest];
       // [self.videoManager stop];
    }
}

- (void)changePlaybackStatus
{
    NSMutableURLRequest *request = nil;
    NSString            *rateString = @"/rate?value=1.00000";
    
    if (self.paused) {
        rateString = @"/rate?value=0.00000";
    }
    
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:rateString
                                                         relativeToURL:self.baseUrl]];
    request.HTTPMethod = @"POST";
    [self setCommonHeadersForRequest:request];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               //   Do nothing on completion
                           }];
}

- (void)stoppedWithError:(NSError *)error
{
    self.paused = NO;
    self.airplaying = NO;
    [self.infoTimer invalidate];
    self.playbackPosition = 0;
    //[self.delegate positionUpdated:self.playbackPosition];
   // [self.delegate durationUpdated:0];
    //[self.delegate airplayStoppedWithError:error];
}

#pragma mark -
#pragma mark GCDAsyncSocket methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"socket:didConnectToHost:port: called");
}

- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength
           tag:(long)tag
{
    NSLog(@"socket:didWritePartialDataOfLength:tag: called");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    if (tag == kAHRequestTagReverse) {
        //  /reverse request data written
    } else if (tag == kAHRequestTagPlay) {
        //  /play request data written
        self.airplaying = YES;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString    *replyString = nil;
    NSRange     range;
    
    replyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"socket:didReadData:withTag: data:\r\n%@", replyString);
    
    if (tag == kAHRequestTagPlay) {
        //  /play request reply received and read
        range = [replyString rangeOfString:@"HTTP/1.1 200 OK"];
        
        if (range.location != NSNotFound) {
            self.airplaying = YES;
            self.paused = NO;
           // [self.delegate setPaused:self.paused];
           // [self.delegate durationUpdated:self.videoManager.duration];
            
            self.infoTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f
                                                              target:self
                                                            selector:@selector(infoRequest)
                                                            userInfo:nil
                                                             repeats:YES];
        }
        
        NSLog(@"read data for /play reply");
    }
}

- (void)writeOK
{
    NSData *okData = [@"ok" dataUsingEncoding:NSUTF8StringEncoding];
    [self.mainSocket writeData:okData withTimeout:10.0f tag:kAHHeartBeatTag];
}


/*
 
 +[<JOiTunesImportHelper: 0x106aacf10> importAudioFileAtPath:/var/mobile/Media/Downloads/Drake - Friends with Money (Produced by Tommy Gunnz) [0p].m4a mediaKind:song withMetadata:{
 albumName = "Unknown Album 2";
 artist = "Unknown Artist";
 duration = 247734;
 software = "Lavf56.40.101";
 title = "Drake - Friends with Money (Produced by Tommy Gunnz) [0p]";
 type = Music;
 year = 2016;
	} serverURL:http://localhost:52387/Media/Downloads]
 
 */

- (void)importFileWithJO:(NSString *)theFile duration:(NSNumber *)duration
{
   // NSLog(@"importFileWithJO: %@", theFile);
    //[self testRunServer];
    //NSData *imageData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/imageTest.png"];
    NSData *imageData = [NSData dataWithContentsOfFile:@"/Applications/yourTube.app/GenericArtwork.png"];
    NSDictionary *theDict = @{@"albumName": @"Unknown Album 2", @"artist": @"Unknown Artist", @"duration": duration, @"imageData":imageData, @"type": @"Music", @"software": @"Lavf56.40.101", @"title": [[theFile lastPathComponent] stringByDeletingPathExtension], @"year": @2016};
    Class joitih = NSClassFromString(@"JOiTunesImportHelper");
    [joitih importAudioFileAtPath:theFile mediaKind:@"song" withMetadata:theDict serverURL:@"http://localhost:52387/Media/Downloads"];
    
    //[self importFile:theFile withData:theDict serverURL:@"http://localhost:57287/Media/Downloads"];
}


//a failed attempt to replicate what JODebox does to import files into the library.

- (void)importFile:(NSString *)filePath withData:(NSDictionary *)inputDict serverURL:(NSString *)serverURL
{
    NSLog(@"importFile: %@", filePath);
    SSDownloadMetadata *metad = [[SSDownloadMetadata alloc] initWithKind:@"song"]; //r10
    NSString *downloads = @"/var/mobile/Media/Downloads"; //r6
    // NSString *serverArg = @"http://localhost:port/Media/Downloads"; //var_3C
    NSNumber *duration = inputDict[@"duration"];//get duration from input data
    
    
    NSString *fileServerPath = [filePath stringByReplacingOccurrencesOfString:downloads withString:serverURL]; //r4
    NSLog(@"fileServerPath: %@", fileServerPath);
    NSString *escapedPath = [fileServerPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //r5
    NSLog(@"escapedPath: %@", escapedPath);
    NSURL *urlString = [NSURL URLWithString:escapedPath]; //var_5C
    NSLog(@"urlString: %@", urlString);
    NSURLRequest *fileURLRequest = [NSURLRequest requestWithURL:urlString];
    double durationDouble = [duration doubleValue]; //r6
    NSNumber *updatedDuration = [NSNumber numberWithDouble:durationDouble*1000];
    [metad setDurationInMilliseconds:updatedDuration];
    
    [metad setArtistName:@"Unknown"];
    [metad setGenre:@"Unknown"];
    [metad setReleaseYear:@2016];
    [metad setPurchaseDate:[NSDate date]];
    [metad setShortDescription:@"This is a test"];
    [metad setLongDescription:@"This is a long test"];
    [metad setBundleIdentifier:@"com.nito.itunesimport"];
    [metad setComposerName:@"youTube Browser"];
    [metad setCopyright:@"© 2016 youTube Browser"];
    NSString *transID = [filePath lastPathComponent];
    [metad setTransactionIdentifier:transID];
    [metad setTitle:transID];
    NSData *imageData = inputDict[@"imageData"];
    NSURL *imageURL = nil;
    NSURLRequest *imageURLRequest = nil;
    if (imageData != nil){
        
        NSString *imageFile = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpeg"];
        [imageData writeToFile:imageFile atomically:YES];
        imageURL = [NSURL fileURLWithPath:imageFile];
        imageURLRequest = [NSURLRequest requestWithURL:imageURL];
    }
    
    
    
    SSDownload *fileDownload = [[SSDownload alloc] initWithDownloadMetadata:metad];
    if (imageURLRequest != nil)
    {
        SSDownloadAsset *imageAsset = [[SSDownloadAsset alloc] initWithURLRequest:imageURLRequest];
        [fileDownload addAsset:imageAsset forType:@"artwork"];
    }
    
    if (fileURLRequest != nil) //it better not be!
    {
        SSDownloadAsset *fileAsset = [[SSDownloadAsset alloc] initWithURLRequest:fileURLRequest];
        [fileDownload addAsset:fileAsset forType:@"media"];
    }
    
    SSDownloadQueue *dlQueue = [[SSDownloadQueue alloc] initWithDownloadKinds:[SSDownloadQueue mediaDownloadKinds]];
    SSDownloadManager *manager = [dlQueue downloadManager];
    [manager addDownloads:@[fileDownload] completionBlock:nil];
}


@end

