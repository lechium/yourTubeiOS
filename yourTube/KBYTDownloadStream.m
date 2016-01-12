//
//  KBYTDownloadStream.m
//  Seas0nPass
//
//  Created by Kevin Bradley on 3/9/07.
//  Copyright 2007 nito, LLC. All rights reserved.
//

/*
 
 class adapted from hawkeye's KBYTDownloadStream class for downloading youtube files, largely pruned to remove irrelevant sections + updated to cancel the xfer + remodified/updated to use blocks instead of antiquated delegate methods.
 
 */

#import "KBYTDownloadStream.h"


@implementation KBYTDownloadStream

@synthesize downloadLocation;

#pragma mark -
#pragma mark •• URL code

- (void)dealloc
{
    downloadLocation = nil;
}

- (void)cancel
{
    
    [self.downloader cancel];
}


- (long long)updateFrequency
{
    return updateFrequency;
}

- (void)setUpdateFrequency:(long long)newUpdateFrequency
{
    updateFrequency = newUpdateFrequency;
}

- (id)init
{
    if(self = [super init]) {
        [self setUpdateFrequency:1];
        
    }
    
    return self;
}

/*
 
 - (void)downloadStream:(KBYTStream *)stream
 {
 
 self.downloader = [[URLDownloader alloc] initWithDelegate:self];
 NSURL *url = [stream url];
 NSLog(@"downloading url: %@ type: %@", [stream url] ,[stream type]);
 NSURLRequestCachePolicy policy = NSURLRequestUseProtocolCachePolicy;
 NSTimeInterval timeout = 60.0;
 NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:policy timeoutInterval:timeout];
 [self.downloader download:request withCredential:nil];
 self.downloading = true;
 }
 
 */

- (void)downloadStream:(KBYTStream *)inputStream
              progress:(FancyDownloadProgressBlock)progressBlock
             completed:(DownloadCompletedBlock)completedBlock
{
    self.CompletedBlock = completedBlock;
    self.FancyProgressBlock = progressBlock;
    
    self.downloadLocation = [[self downloadFolder] stringByAppendingPathComponent:inputStream.outputFilename];
    
    if (inputStream.audioStream != nil)
    {
        audioStream = inputStream.audioStream;
        self.downloadMode = 1;
    } else {
        self.downloadMode = 0;
    }
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:inputStream.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    self.downloader = [[URLDownloader alloc] initWithDelegate:self];
    [self.downloader download:theRequest withCredential:nil];
    //urlDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
    //[urlDownload setDestination:downloadLocation allowOverwrite:YES];
    
}



- (void)urlDownloader:(URLDownloader *)urlDownloader didFinishWithData:(NSData *)data
{
    if(self.downloader == urlDownloader) {
        
        NSLog(@"downloadLocation: %@", self.downloadLocation);
        [data writeToFile:[self downloadLocation] atomically:TRUE];
        if ([downloadLocation.pathExtension isEqualToString:@"aac"])
        {
            self.FancyProgressBlock(0, @"Fixing audio...");
            NSInteger volumeInt = 256;
          
            
             [[KBYourTube sharedInstance] fixAudio:downloadLocation volume:volumeInt completionBlock:^(NSString *newFile) {
             if (self.CompletedBlock != nil)
             {
                 
                 [[KBYourTube sharedInstance] importFileWithJO:newFile duration:self.trackDuration];
             self.CompletedBlock(newFile);
             }
             }];
            return;
        }
        
        //non adaptive files that are already multiplexed will be generically processed if we get this far
        if (self.CompletedBlock != nil)
        {
            self.CompletedBlock(downloadLocation);
        }
        
        
        
    }
    
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didChangeStateTo:(URLDownloaderState)state
{
    LOG_SELF;
}

- (void)urlDownloader:(URLDownloader *)td didFailOnAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    LOG_SELF;
}
- (void)urlDownloader:(URLDownloader *)td didFailWithError:(NSError *)error {
LOG_SELF;
}
- (void)urlDownloader:(URLDownloader *)td didFailWithNotConnectedToInternetError:(NSError *)error{
LOG_SELF;
}

- (void)urlDownloaderDidStart:(URLDownloader *)td {
LOG_SELF;
}
- (void)urlDownloaderDidCancelDownloading:(URLDownloader *)td {
LOG_SELF;
    [self cancel];

}
- (void)urlDownloader:(URLDownloader *)td didReceiveData:(NSData *)data {
    float percentComplete = [td downloadCompleteProcent];
    if (self.ProgressBlock != nil)
    {
        self.ProgressBlock(percentComplete);
    }
    
    if (self.FancyProgressBlock != nil)
    {
        self.FancyProgressBlock(percentComplete, @"");
    }
    //NSLog(@"percentComplete: %f", percentComplete);
    
}

@end
