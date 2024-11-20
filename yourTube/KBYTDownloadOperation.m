//
//  YTDownloadOperation.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import "KBYTDownloadOperation.h"
#import "yourTubeApplication.h"
#import "KBYTDownloadsTableViewController.h"
#import "NSFileManager+Size.h"
#import "KBSlider.h"
@import ffmpegkit;
@import M3U8Kit;

@interface KBYTDownloadOperation () {
    BOOL _finished;
    BOOL _executing;
}

@property (readwrite, assign) NSTimeInterval startTime;
@property (nonatomic) FFmpegSession *ffmpegSession;
@end

//download operation class, handles file downloads.


@implementation KBYTDownloadOperation

@synthesize downloadInfo, downloader, downloadLocation, trackDuration, CompletedBlock;

- (void)ffmpegDownload {
    NSString *url = downloadInfo[@"url"];
    NSInteger pid = [downloadInfo[@"programId"] integerValue];
    DLog(@"self.downloadLocation: %@", self.downloadLocation);
    NSString *commandLineUlt = [NSString stringWithFormat:@"-y -i %@ -map 0:p:%lu -c copy '%@'", url, pid, self.downloadLocation];
    DLog(@"commandLine: %@", commandLineUlt);
    NSInteger currentLogLevel = [FFmpegKitConfig getLogLevel];
    NSString *lls = [FFmpegKitConfig logLevelToString:currentLogLevel];
    DLog(@"currentLogLevel: %lu string: %@", currentLogLevel, lls);
    [FFmpegKitConfig setLogLevel:LevelAVLogQuiet];
    currentLogLevel = [FFmpegKitConfig getLogLevel];
    lls = [FFmpegKitConfig logLevelToString:currentLogLevel];
    DLog(@"updatedLogLevel: %lu string: %@", currentLogLevel, lls);
    self.ffmpegSession = [FFmpegKit executeAsync:commandLineUlt withCompleteCallback:^(FFmpegSession* session){
        SessionState state = [session getState];
        ReturnCode *returnCode = [session getReturnCode];
        
        // CALLED WHEN SESSION IS EXECUTED
        
        DLog(@"FFmpeg process exited with state %@ and rc %@.%@", [FFmpegKitConfig sessionStateToString:state], returnCode, [session getFailStackTrace]);
        [self setExecuting:false];
        [self setFinished:true];
        dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_IOS
            if (self.CompletedBlock != nil) {
                self.CompletedBlock(self.downloadLocation);
            }
            yourTubeApplication *appDelegate = (yourTubeApplication *)[[UIApplication sharedApplication] delegate];
            if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]]){
                [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] delayedReloadData];
            }
#endif
        });
    } withLogCallback:^(Log *log) {
        
        // CALLED WHEN SESSION PRINTS LOGS
        //DLog(@"log: %@", log.getMessage);
        //NSDictionary *status = [log.getMessage ffmpegStatus];
        //DLog(@"status: %@", status);
    } withStatisticsCallback:^(Statistics *statistics) {
        
        // CALLED WHEN SESSION GENERATES STATISTICS
        double duration = [downloadInfo[@"duration"] doubleValue];
        double elapsedSeconds = statistics.getTime / 1000.0;
        double remainingTime = duration - elapsedSeconds;
        double estimatedTime = remainingTime / statistics.getSpeed;
        double percentComplete = elapsedSeconds / duration;
        DLog(@"frame: %d time: %.2f, speed: %f ETA: %.f %.2f complete", statistics.getVideoFrameNumber, elapsedSeconds, statistics.getSpeed, estimatedTime, percentComplete);
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self setDownloadProgress:percentComplete];
            //self.progressLabel.stringValue = @"Downloading video...";
#if TARGET_OS_IOS
            yourTubeApplication *appDelegate = (yourTubeApplication *)[[UIApplication sharedApplication] delegate];
            KBYTDownloadsTableViewController *visibleView = (KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController];
            if ([visibleView isKindOfClass:[KBYTDownloadsTableViewController class]]) {
                NSDictionary *info = @{@"videoId": self.downloadInfo[@"videoID"],
                                       @"completionPercent": [NSNumber numberWithFloat:percentComplete],
                                       @"estimatedDuration": [NSString stringWithFormat:@"ETA: %@", [[KBYTDownloadOperation elapsedTimeFormatter] stringFromTimeInterval:estimatedTime]] };
                [visibleView updateDownloadProgress:info];
            }
#endif
        });
        //[self setDownloadProgress:percentComplete*100];
    }];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isExecuting {
    return _executing;
}

- (BOOL)isAsynchronous {
    return true;
}

- (id)initWithInfo:(NSDictionary *)downloadDictionary completed:(DownloadCompletedBlock)theBlock {
    self = [super init];
    DLog(@"init with info: %@", downloadDictionary);
    downloadInfo = downloadDictionary;
    self.name = downloadInfo[@"title"];
    NSString *codec = downloadInfo[@"codec"];
    NSString *suffix = @"mp4";
    if ([codec containsString:@"vp09"]){
        suffix = @"ts";
    }
    self.downloadLocation = [[[self downloadFolder] stringByAppendingPathComponent:[self.name stringByReplacingOccurrencesOfString:@"/" withString:@" "]] stringByAppendingPathExtension:suffix];
    NSString *imageURL = downloadInfo[@"images"][@"standard"];
    NSData *downloadData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
    NSString *outputJPEG = [[[self downloadLocation] stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
    [downloadData writeToFile:outputJPEG atomically:true];
    NSInteger durationSeconds = [downloadDictionary[@"duration"] integerValue];
    trackDuration = durationSeconds*1000;
    CompletedBlock = theBlock;
    
    return self;
}

- (void)cancel {
    [super cancel];
    [self.ffmpegSession cancel];
}

- (void)main {
    [self start];
}

- (void)sendAudioCompleteMessage {
    #if TARGET_OS_IOS
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
    NSDictionary *info = @{@"file": self.downloadLocation.lastPathComponent};
    
    [center sendMessageName:@"org.nito.dllistener.audioImported" userInfo:info];
#endif
}

- (void)start {
    [self setExecuting:true];
    if (self.ffmpegSession) {
        return;
    }
    [self ffmpegDownload];
}


- (CGFloat)exponentialMovingAverage:(NSArray *)data smoothing:(CGFloat)smoothing {
    if (data.count == 1) {
        return [[data firstObject] floatValue];
    }
    NSInteger samples = [data count];
    CGFloat average = [data floatAverage];
    TLog(@"average: %f", average);
    CGFloat lastSpeed = [[data lastObject] floatValue];
    return (smoothing * lastSpeed) + ((1 - smoothing) * average);
}

+ (NSDateComponentsFormatter *)elapsedTimeFormatter {
    static dispatch_once_t minOnceToken;
    static NSDateComponentsFormatter *elapsedTimer = nil;
    if(elapsedTimer == nil) {
        dispatch_once(&minOnceToken, ^{
            elapsedTimer = [[NSDateComponentsFormatter alloc] init];
            elapsedTimer.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
            elapsedTimer.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
            elapsedTimer.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        });
    }
    return elapsedTimer;
}

@end
