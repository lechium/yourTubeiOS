//
//  YTBrowserHelper.h
//  YTBrowserHelper
//
//  Created by Kevin Bradley on 12/30/15.
//  Copyright © 2015 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "GCDWebServer/GCDWebServer.h"
#import "GCDAsyncSocket.h"
#import "yourTube/Download/URLDownloader.h"
#import "NSTask.h"

#define LOG_SELF        NSLog(@"%@ %@", self, NSStringFromSelector(_cmd))

@interface NSTask (convenience)

- (void)waitUntilExit;

@end

@interface YTBrowserHelper : NSObject


+ (id)sharedInstance;
- (void)importFile:(NSString *)filePath withData:(NSDictionary *)inputDict serverURL:(NSString *)serverURL;

//@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, strong) NSTimer *airplayTimer;
@property (nonatomic, strong) NSDictionary *airplayDictionary;
@property (nonatomic, strong) NSString *deviceIP;
@property (nonatomic, strong) NSString *sessionID;
@property (readwrite, assign) BOOL airplaying;

@property (strong, nonatomic) NSURL                 *baseUrl;
@property (strong, nonatomic) NSString              *prevInfoRequest;
@property (strong, nonatomic) NSMutableData         *responseData;
@property (strong, nonatomic) NSMutableData         *data;
@property (strong, nonatomic) NSTimer               *infoTimer;
@property (strong, nonatomic) NSDictionary          *serverInfo;
@property (strong, nonatomic) GCDAsyncSocket        *mainSocket;
@property (strong, nonatomic) NSOperationQueue      *operationQueue;
@property (strong, nonatomic) NSOperationQueue      *downloadQueue;
@property (nonatomic) BOOL                          paused;
@property (nonatomic) double                        playbackPosition;
@property (nonatomic) uint8_t                       serverCapabilities;

- (void)togglePaused;
- (void)setCommonHeadersForRequest:(NSMutableURLRequest *)request;
- (void)playRequest:(NSString *)httpFilePath;
- (void)infoRequest;
- (void)getPropertyRequest:(NSUInteger)property;
- (void)stopRequest;
- (void)changePlaybackStatus;
- (void)stoppedWithError:(NSError *)error;
- (void)startAirplayFromDictionary:(NSDictionary *)airplayDict;
- (void)stopPlayback;
- (NSDictionary *)airplayState;
- (void)fixAudio:(NSString *)theFile volume:(NSInteger)volume completionBlock:(void(^)(NSString *newFile))completionBlock;
- (void)importFileWithJO:(NSString *)theFile duration:(NSNumber *)duration;
@end

@interface YTDownloadOperation: NSOperation <URLDownloaderDelegate>

typedef void(^DownloadCompletedBlock)(NSString *downloadedFile);

@property (nonatomic, strong) NSDictionary *downloadInfo;
@property (nonatomic, strong) URLDownloader *downloader;
@property (nonatomic, strong) NSString *downloadLocation;
@property (strong, atomic) void (^ProgressBlock)(double percentComplete);
@property (strong, atomic) void (^FancyProgressBlock)(double percentComplete, NSString *status);
@property (strong, atomic) void (^CompletedBlock)(NSString *downloadedFile);
@property (readwrite, assign) NSInteger trackDuration;

- (id)initWithInfo:(NSDictionary *)downloadDictionary
         completed:(DownloadCompletedBlock)theBlock;

@end
