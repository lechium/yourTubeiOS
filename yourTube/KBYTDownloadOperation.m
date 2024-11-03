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

@interface KBYTDownloadOperation ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) AVAssetDownloadTask *downloadTask;
@end

//download operation class, handles file downloads.


@implementation KBYTDownloadOperation

@synthesize downloadInfo, downloader, downloadLocation, trackDuration, CompletedBlock;

/*
 - (NSString *)downloadFolder
 {
 NSFileManager *man = [NSFileManager defaultManager];
 NSString *outputFolder = [self downloadFolder];
 if (![man fileExistsAtPath:outputFolder])
 {
 [man createDirectoryAtPath:outputFolder withIntermediateDirectories:true attributes:nil error:nil];
 }
 return outputFolder;
 }
 */

- (BOOL)isAsynchronous
{
    return true;
}

- (id)initWithInfo:(NSDictionary *)downloadDictionary completed:(DownloadCompletedBlock)theBlock
{
    self = [super init];
    NSLog(@"init with info");
    downloadInfo = downloadDictionary;
    self.name = downloadInfo[@"title"];
    self.downloadLocation = [[self downloadFolder] stringByAppendingPathComponent:downloadDictionary[@"outputFilename"]];
    NSString *imageURL = downloadInfo[@"images"][@"standard"];
    NSData *downloadData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
    NSString *outputJPEG = [[[self downloadLocation] stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
    [downloadData writeToFile:outputJPEG atomically:true];
    NSInteger durationSeconds = [downloadDictionary[@"duration"] integerValue];
    trackDuration = durationSeconds*1000;
    CompletedBlock = theBlock;
    
    return self;
}

- (void)cancel
{
    [super cancel];
    //[self.downloader cancel];
    [[self downloadTask] cancel];
}

- (void)main
{
    [self start];
    /*
    NSURL *url = [NSURL URLWithString:downloadInfo[@"url"]];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    self.downloader = [[URLDownloader alloc] initWithDelegate:self];
    [self.downloader download:theRequest withCredential:nil];
     */
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didChangeStateTo:(URLDownloaderState)state
{
    NSLog(@"Download state: %u", state);
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didFailWithError:(NSError *)error
{
    self.CompletedBlock(nil);
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didFailWithNotConnectedToInternetError:(NSError *)error
{
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didFinishWithData:(NSData *)data
{
    [data writeToFile:[self downloadLocation] atomically:TRUE];
    
    //if we are dealing with an audio file we need to re-encode it in ffmpeg to get a playable file. (and to bump volume)
    /*
    if ([downloadLocation.pathExtension isEqualToString:@"aac"])
    {
        
        //for now the audio is bumped to a static 256 increase, this may change later to be customizable.
        NSInteger volumeInt = 256;
        
        //do said re-encoding in ffmpeg
        [[YTBrowserHelper sharedInstance] fixAudio:downloadLocation volume:volumeInt completionBlock:^(NSString *newFile) {
            
            if (self.CompletedBlock != nil)
            {
                //import the file to the music library using JODebox
                [[YTBrowserHelper sharedInstance] importFileWithJO:newFile duration:self.trackDuration];
                [self sendAudioCompleteMessage];
                self.CompletedBlock(newFile);
            }
        }];
        return;
    }
    */
    //all other media goes through here, no conversion and imports necessary.
    if (self.CompletedBlock != nil)
    {
        self.CompletedBlock(downloadLocation);
    }
    
    
    
}

- (void)sendAudioCompleteMessage
{
    #if TARGET_OS_IOS
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
    NSDictionary *info = @{@"file": self.downloadLocation.lastPathComponent};
    
    [center sendMessageName:@"org.nito.dllistener.audioImported" userInfo:info];
#endif
}

//use CPDistributedMessagingCenter to relay progress details back to the yourTube/tuyu application.

- (void)urlDownloader:(URLDownloader *)urlDownloader didReceiveData:(NSData *)data
{
    //
    float percentComplete = [urlDownloader downloadCompleteProcent];
    // NSLog(@"percentComplete: %f", percentComplete);
    #if TARGET_OS_IOS
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
    NSDictionary *info = @{@"file": self.downloadLocation.lastPathComponent,@"completionPercent": [NSNumber numberWithFloat:percentComplete] };
    
    [center sendMessageName:@"org.nito.dllistener.currentProgress" userInfo:info];
#endif
}

- (void)downloadCurrentMedia:(KBYTMedia *)media {
    NSURL *url = [NSURL URLWithString:[media hlsManifest]];
    NSString *title = media.title;
    NSURL *imageURL = [NSURL URLWithString:media.images[@"high"]];
    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    self.downloadIdentifier = media.videoId;
    [self setupAssetDownloadWithURL:url withTitle:title andArtworkData:imageData];
}

- (void)setupAssetDownloadWithURL:(NSURL*)url withTitle:(NSString *)assetTitle andArtworkData:(NSData *)artworkData {
    LOG_SELF;
#if TARGET_OS_IOS
    // Create new background session configuration.
    _sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_downloadIdentifier];
    
    // Create a new AVAssetDownloadURLSession with background configuration, delegate, and queue
    self.downloadSession = [AVAssetDownloadURLSession sessionWithConfiguration:_sessionConfiguration assetDownloadDelegate:self delegateQueue:NSOperationQueue.mainQueue];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    
    // Create new AVAssetDownloadTask for the desired asset
    AVAssetDownloadTask *downloadTask = [_downloadSession assetDownloadTaskWithURLAsset:asset assetTitle:assetTitle assetArtworkData:artworkData options:nil];
    
    // Start task and begin download
    [downloadTask resume];
#endif
}

- (void)restorePendingDownloads {
    LOG_SELF;
    // Create session configuration with ORIGINAL download identifier
    _sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_downloadIdentifier];
    
    // Create a new AVAssetDownloadURLSession
    _downloadSession = [AVAssetDownloadURLSession sessionWithConfiguration:_sessionConfiguration assetDownloadDelegate:self delegateQueue:NSOperationQueue.mainQueue];
 
    // Grab all the pending tasks associated with the downloadSession
    [_downloadSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
        // For each task, restore the state in the app
        for (AVAssetDownloadTask *task in tasks) {
            // Restore asset, progress indicators, state, etc...
            AVURLAsset *asset = [task URLAsset];
        }
    }];
}

- (void)start
{
    //self.session = [self backgroundSessionWithId:self.downloadInfo[@"title"]];
    
    if (self.downloadTask)
    {
        return;
    }
    
    NSLog(@"starting task...");
    /*
     Create a new download task using the URL session. Tasks start in the “suspended” state; to start a task you need to explicitly call -resume on a task after creating it.
     */
    NSURL *downloadURL = [NSURL URLWithString:downloadInfo[@"url"]];
    /*
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    self.downloadTask = [self.session downloadTaskWithRequest:request];
    [self.downloadTask resume];
     */
    _sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.downloadInfo[@"title"]];
    
    // Create a new AVAssetDownloadURLSession with background configuration, delegate, and queue
    self.downloadSession = [AVAssetDownloadURLSession sessionWithConfiguration:_sessionConfiguration assetDownloadDelegate:self delegateQueue:NSOperationQueue.mainQueue];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:downloadURL];
    
    // Create new AVAssetDownloadTask for the desired asset
    self.downloadTask = [_downloadSession assetDownloadTaskWithURLAsset:asset assetTitle:self.downloadInfo[@"title"] assetArtworkData:nil options:nil];
    
    // Start task and begin download
    [self.downloadTask resume];
}

- (void)URLSession:(NSURLSession *)session assetDownloadTask:(AVAssetDownloadTask *)assetDownloadTask didLoadTimeRange:(CMTimeRange)timeRange totalTimeRangesLoaded:(NSArray<NSValue *> *)loadedTimeRanges timeRangeExpectedToLoad:(CMTimeRange)timeRangeExpectedToLoad {
    LOG_SELF;
    CGFloat percentComplete = 0.0;
    // Iterate through the loaded time ranges
    for (NSValue *value in loadedTimeRanges) {
        // Unwrap the CMTimeRange from the NSValue
        CMTimeRange loadedTimeRange = [value CMTimeRangeValue];
        // Calculate the percentage of the total expected asset duration
        percentComplete += CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration);
    }
    percentComplete *= 100;
    DLog(@"percent complete: %.0f", percentComplete);
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self setDownloadProgress:percentComplete];
        //self.progressLabel.stringValue = @"Downloading video...";
#if TARGET_OS_IOS
            yourTubeApplication *appDelegate = (yourTubeApplication *)[[UIApplication sharedApplication] delegate];
            if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
            {
                NSDictionary *info = @{@"file": self.downloadLocation.lastPathComponent,@"completionPercent": [NSNumber numberWithFloat:percentComplete] };
                [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] updateDownloadProgress:info];
            }
#endif
    });
    // Update UI state: post notification, update KVO state, invoke callback, etc.
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    /*
     Report progress on the task.
     If you created more than one task, you might keep references to them and report on them individually.
     */
    
    if (downloadTask == self.downloadTask)
    {
        double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
        //NSLog(@"DownloadTask: %@ progress: %lf", downloadTask, progress);
        dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_IOS
            yourTubeApplication *appDelegate = (yourTubeApplication *)[[UIApplication sharedApplication] delegate];
            if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
            {
                NSDictionary *info = @{@"file": self.downloadLocation.lastPathComponent,@"completionPercent": [NSNumber numberWithFloat:progress] };
                [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] updateDownloadProgress:info];
            }
#endif
            // self.progressView.progress = progress;
        });
    }
}

- (void)URLSession:(NSURLSession *)session assetDownloadTask:(AVAssetDownloadTask *)assetDownloadTask didFinishDownloadingToURL:(NSURL *)location {
    LOG_SELF;
    DLog(@"finished downloading file to URL: %@ path: %@", location, location.path);
    self.assetDownloadURL = location;
    dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_IOS
        if (self.CompletedBlock != nil) {
            DLog(@"relative path: %@", location.relativePath);
            self.downloadLocation = location.relativePath;
            self.CompletedBlock(location.relativePath);
        }
        yourTubeApplication *appDelegate = (yourTubeApplication *)[[UIApplication sharedApplication] delegate];
        if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
        {
            //NSDictionary *info = @{@"file": self.downloadLocation.lastPathComponent,@"completionPercent": [NSNumber numberWithFloat:100] };
            //[(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] updateDownloadProgress:info];
            [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] delayedReloadData];
        }
#endif
    });
    [[NSUserDefaults standardUserDefaults] setValue:location.relativePath forKey:@"assetPath"];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:location];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        
    });

}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    
    /*
     The download completed, you need to copy the file at targetPath before the end of this block.
     As an example, copy the file to the Documents directory of your app.
     */
    
    NSURL *destinationURL = [NSURL fileURLWithPath:[self downloadLocation]];
    NSError *errorCopy;
    
    // For the purposes of testing, remove any esisting file at the destination.
    [FM removeItemAtURL:destinationURL error:NULL];
    BOOL success = [FM copyItemAtURL:downloadURL toURL:destinationURL error:&errorCopy];
    
    if (success)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_IOS
            yourTubeApplication *appDelegate = (yourTubeApplication *)[[UIApplication sharedApplication] delegate];
            if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
            {
                [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] delayedReloadData];
            }
#endif
        });
    }
    else
    {
        /*
         In the general case, what you might do in the event of failure depends on the error and the specifics of your application.
         */
        NSLog(@"Error during the copy: %@", [errorCopy localizedDescription]);
    }
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    
    if (error == nil)
    {
        NSLog(@"Task: %@ completed successfully", task);
        if (self.CompletedBlock != nil)
        {
            self.CompletedBlock(downloadLocation);
        }
    }
    else
    {
        NSLog(@"Task: %@ completed with error: %@", task, [error localizedDescription]);
        if (self.CompletedBlock != nil)
        {
            self.CompletedBlock(downloadLocation);
        }
    }
    
    double progress = (double)task.countOfBytesReceived / (double)task.countOfBytesExpectedToReceive;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"progress; %f", progress);
        //  self.progressView.progress = progress;
    });
    
    self.downloadTask = nil;
}


- (NSURLSession *)backgroundSessionWithId:(NSString *)sessionID
{
    /*
     Using disptach_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
     */
    static NSURLSession *session = nil;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionID];
    session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    return session;
}




@end
