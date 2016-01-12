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

@interface JOiTunesImportHelper : NSObject

+ (_Bool)importAudioFileAtPath:(id)arg1 mediaKind:(id)arg2 withMetadata:(id)arg3 serverURL:(id)arg4;
+ (id)downloadManager;

@end

@implementation YTBrowserHelper

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


- (void)startGCDWebServer {} //keep the compiler happy

/* 
 
 the music import process is needlessly convoluted to "protect" us, SSDownloads can't be triggered via local files
 JODebox runs a server the open source project GCDWebServer, im pretty sure all it does is just host files from
 /var/mobile/Media/Downloads after preparing them to be compatible to keep SSDownloadManager queues happy in thinking
 the file is coming from a remote source.

 */

//this method is never actually called inside YTBrowserHelper, we hook into -(id)init in SpringBoard and add this
//method in YTBrowser.xm

- (void)handleMessageName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    [self startGCDWebServer]; //start the GCDServer before we kick off the import.
  
    //right now the userInfo dict only has a filePath and a duration of the input file
    //remember this is being called from inside SpringBoard and not YTBrowserHelper, so this is how we pass the
    //information to our JODebox wrapper.
    [[YTBrowserHelper sharedInstance] importFileWithJO:userInfo[@"filePath"] duration:userInfo[@"duration"]];
}


+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static YTBrowserHelper *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            shared = [YTBrowserHelper new];
        });
    }
    
    return shared;
    
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

