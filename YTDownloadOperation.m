//
//  YTDownloadOperation.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import "YTDownloadOperation.h"

//download operation class, handles file downloads.

@implementation YTDownloadOperation

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
    [self.downloader cancel];
}

- (void)main
{
    NSURL *url = [NSURL URLWithString:downloadInfo[@"url"]];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    self.downloader = [[URLDownloader alloc] initWithDelegate:self];
    [self.downloader download:theRequest withCredential:nil];
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didChangeStateTo:(URLDownloaderState)state
{
    NSLog(@"Download state: %u", state);
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didFailWithError:(NSError *)error
{
    LOG_SELF;
    self.CompletedBlock(nil);
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didFailWithNotConnectedToInternetError:(NSError *)error
{
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didFinishWithData:(NSData *)data
{
    LOG_SELF;
    [data writeToFile:[self downloadLocation] atomically:TRUE];
    
    //if we are dealing with an audio file we need to re-encode it in ffmpeg to get a playable file. (and to bump volume)
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
    
    //all other media goes through here, no conversion and imports necessary.
    if (self.CompletedBlock != nil)
    {
        self.CompletedBlock(downloadLocation);
    }
    
    
    
}

- (void)sendAudioCompleteMessage
{
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
    NSDictionary *info = @{@"file": self.downloadLocation.lastPathComponent};
    
    [center sendMessageName:@"org.nito.dllistener.audioImported" userInfo:info];
}

//use CPDistributedMessagingCenter to relay progress details back to the yourTube/tuyu application.

- (void)urlDownloader:(URLDownloader *)urlDownloader didReceiveData:(NSData *)data
{
    //
    float percentComplete = [urlDownloader downloadCompleteProcent];
    // NSLog(@"percentComplete: %f", percentComplete);
    CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
    NSDictionary *info = @{@"file": self.downloadLocation.lastPathComponent,@"completionPercent": [NSNumber numberWithFloat:percentComplete] };
    
    [center sendMessageName:@"org.nito.dllistener.currentProgress" userInfo:info];
    
}

- (void)urlDownloaderDidStart:(URLDownloader *)urlDownloader
{
    
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didFailOnAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    
}



@end
