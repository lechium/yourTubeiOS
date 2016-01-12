//
//  YTBrowserHelper.mm
//  YTBrowserHelper
//
//  Created by Kevin Bradley on 12/30/15.
//  Copyright © 2015 nito. All rights reserved.
//

#import "YTBrowserHelper.h"
#import "ipodimport.h"
#import "Gremlin.h"
#import <Foundation/Foundation.h>
#import "AppSupport/CPDistributedMessagingCenter.h"


@interface NSTask (convenience)

- (void)waitUntilExit;

@end

@implementation NSTask (convenience)

- (void) waitUntilExit
{
    NSTimer	*timer = nil;
    
    while ([self isRunning])
    {
        NSDate	*limit;
        
        /*
         *	Poll at 0.1 second intervals.
         */
        limit = [[NSDate alloc] initWithTimeIntervalSinceNow: 0.1];
        if (timer == nil)
        {
            timer = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                                     target: nil
                                                   selector: @selector(class)
                                                   userInfo: nil
                                                    repeats: YES];
        }
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                 beforeDate: limit];
        //RELEASE(limit);
    }
    [timer invalidate];
}

@end

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
- (void)startGCDWebServer {}

- (void)handleMessageName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    //if ([[name pathExtension] isEqualToString:@"import"])
    [self startGCDWebServer];
     NSLog(@"userInfo: %@", userInfo);
    NSString *importFile = userInfo[@"filePath"];
    [[YTBrowserHelper sharedInstance] importFileWithJO:importFile duration:userInfo[@"duration"]];
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

- (void)fileCopyTest:(NSString *)theFile
{
    NSFileManager *man = [NSFileManager defaultManager];
//    NSString *fileName = @"Drake - Free Spirit ft. Rick Ross [0p].m4a";
    NSString *outputFile = [NSString stringWithFormat:@"/var/mobile/Media/Downloads/%@", [[[theFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"m4a"]];
    [man copyItemAtPath:theFile toPath:outputFile error:nil];
    
}

- (void)fixAudio:(NSString *)theFile volume:(NSInteger)volume completionBlock:(void(^)(NSString *newFile))completionBlock
{
    //NSLog(@"fix audio: %@", theFile);
   // NSString *outputFile = [NSString stringWithFormat:@"/var/mobile/Media/Downloads/%@", [[[theFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"m4a"]];
    NSString *outputFile = [[theFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"m4a"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            NSTask *afcTask = [NSTask new];
            [afcTask setLaunchPath:@"/usr/bin/ffmpeg"];
            //iOS change to /usr/bin/ffmpeg and make sure to depend upon com.nin9tyfour.ffmpeg
            NSPipe *pipe = [[NSPipe alloc] init];
            NSFileHandle *handle = [pipe fileHandleForReading];
            
            NSData *outData;
            
            [afcTask setStandardOutput:pipe];
            [afcTask setStandardError:pipe];
            NSString *temp = @"";
            NSMutableArray *lineArray = [[NSMutableArray alloc] init];
            
           
            // [afcTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
            //[afcTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
            NSMutableArray *args = [NSMutableArray new];
            [args addObject:@"-i"];
            [args addObject:theFile];
            
            if (volume == 0){
                [args addObjectsFromArray:[@"-acodec copy -y" componentsSeparatedByString:@" "]];
            } else {
                [args addObject:@"-vol"];
                [args addObject:[NSString stringWithFormat:@"%ld", (long)volume]];
                //[args addObjectsFromArray:[@"-acodec libfdk_aac -ac 2 -ar 44100 -ab 320K -y" componentsSeparatedByString:@" "]];
                //for ios change to
                // -strict -2
                [args addObjectsFromArray:[@"-acodec aac -ac 2 -ar 44100 -ab 320K -strict -2 -y" componentsSeparatedByString:@" "]];
            }
            [args addObject:outputFile];
            [afcTask setArguments:args];
            NSLog(@"/usr/bin/ffmpeg %@", [args componentsJoinedByString:@" "]);
            [afcTask launch];
            while((outData = [handle readDataToEndOfFile]) && [outData length])
            {
                temp = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
                [lineArray addObjectsFromArray:[temp componentsSeparatedByString:@"\n"]];
            //    [temp release];
            }
            NSLog(@"temp: %@", temp);
            //[afcTask waitUntilExit];
        }
      //  [self importFileWithJO:outputFile];
        NSString *finalFile = [NSString stringWithFormat:@"/var/mobile/Media/Downloads/%@", [[[theFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"m4a"]];
        NSFileManager *man = [NSFileManager defaultManager];
        if ([man copyItemAtPath:outputFile toPath:finalFile error:nil] == true)
        {
            NSLog(@"copied to downloads folder successfully!");
            completionBlock(finalFile);
        } else {
            NSLog(@"FAIL");
            completionBlock(outputFile);
        }
        
    });
    
    
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
    NSLog(@"importFileWithJO: %@", theFile);
    //[self testRunServer];
    NSData *imageData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/imageTest.png"];
    NSDictionary *theDict = @{@"albumName": @"Unknown Album 2", @"artist": @"Unknown Artist", @"duration": duration, @"imageData":imageData, @"type": @"Music", @"software": @"Lavf56.40.101", @"title": [[theFile lastPathComponent] stringByDeletingPathExtension], @"year": @2016};
    Class joitih = NSClassFromString(@"JOiTunesImportHelper");
    [joitih importAudioFileAtPath:theFile mediaKind:@"song" withMetadata:theDict serverURL:@"http://localhost:52387/Media/Downloads"];
    
    //[self importFile:theFile withData:theDict serverURL:@"http://localhost:57287/Media/Downloads"];
}

- (void)doJO
{
    NSData *imageData = [NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/imageTest.png"];
    NSDictionary *theDict = @{@"albumName": @"Unknown Album 2", @"artist": @"Drake", @"duration": @180141, @"imageData":imageData, @"type": @"Music", @"software": @"Lavf56.40.101", @"title": @"Drake - Underdog", @"year": @2016};
   // Class joitih = NSClassFromString(@"JOiTunesImportHelper");
    //[joitih importAudioFileAtPath:@"/var/mobile/Media/Downloads/Drake - Underdog [0p].m4a" mediaKind:@"song" withMetadata:theDict serverURL:@"http://localhost:52387/Media/Downloads"];
    
}

/*
 
 r5 = [NSHomeDirectory() retain];
 var_70 = @selector(stringByAppendingPathComponent:);
 r6 = [[r5 stringByAppendingPathComponent:@"Media/Downloads"] retain];
 
 SSDownloadMetadata *metad = [[SSDownloadMetadata alloc] initWithKind:@"song"]; //r10
 NSDictionary *inputDict; //inputargs
 NSString *downloads = @"/var/mobile/Media/Downloads"; //r6
 NSString *serverArg = @"http://localhost:port/Media/Downloads"; //var_3C
 NSNumber *duration = inputDict[@"duration"];//get duration from input data
 
 r4 = [[var_34 stringByReplacingOccurrencesOfString:r6 withString:var_3C] retain];

 r5 = [[r4 stringByAddingPercentEscapesUsingEncoding:0x4] retain];

 var_58 = r5;
 var_5C = [[NSURL URLWithString:r5] retain];
 var_50 = @selector(requestWithURL:);
 var_48 = [[NSURLRequest requestWithURL:r5] retain];
 
 
 NSString *fileServerPath = [inputFileName stringByReplacingOccurrencesOfString:downloads withString:serverArg]; //r4
 NSString *escapedPath = [fileServerPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //r5
 NSURL *urlString = [NSURL URLWithString:escapedPath]; //var_5C
 NSURLRequest *urlRequest = [NSURLRequest requestWithURL:urlString];
 
 r4 = [[r8 objectForKey:@"duration"] retain];
 r6 = [r4 doubleValue];
 
 double durationDouble = [duration doubleValue]; //r6
 
 [metad setDurationInMilliseconds:durationDouble];
 [metad setTitle:inputDict[@"title"]];
 [metad setArtistName:@"Unknown"];
 [metad setGenre:@"Unknown"];
 [metad setReleaseYear:@2016];
 [metad setPurchaseDate:[NSDate date]];
 [metad setShortDescription:@"This is a test"];
 [metad setLongDescription:@"This is a long test"];
 [metad setBundleIdentifier:@"com.nito.itunesimport"];
 [metad setComposerName:@"youTube Browser"];
 
 
 var_60 = [[NSNumber numberWithUnsignedLongLong:r2] retain];
 [r10 setDurationInMilliseconds:r2];
 [r10 setTitle:r4];
 [r10 setArtistName:r4];
 [r10 setGenre:r4];
 [r10 setReleaseYear:r4];
 r4 = [[NSDate date] retain];
 [r10 setPurchaseDate:r4];
 [r10 setShortDescription:0x1f018];
 [r10 setLongDescription:0x1f028];
 [r10 setBundleIdentifier:@"com.ouraigua.ios.itunesimporter"];
 [r10 setComposerName:@"Safari Downloader+"];
 
 
 */

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
   // SSDownloadQueue *dlQueue = [[SSDownloadQueue alloc] initWithDownloadKinds:[SSDownloadQueue mediaDownloadKinds]];
    //SSDownloadManager *manager = [dlQueue downloadManager];
    Class joitih = NSClassFromString(@"JOiTunesImportHelper");
    SSDownloadManager *manager = [joitih downloadManager];
    NSLog(@"downloadManager: %@", manager);
    [manager addDownloads:@[fileDownload] completionBlock:nil];
}


- (void) doScience
{
    
    
    NSString *path = @"https://dl.dropboxusercontent.com/u/16129573/5th.m4a";
     // NSString *path = [[NSBundle mainBundle] pathForResource:@"LightyLight" ofType:@"m4a"];
   // NSString *path = @"https://dl.dropboxusercontent.com/u/16129573/Lights.m4a";
  //  NSString *path = @"/var/mobile/Media/Downloads/gremlin.JOQTqf4th.m4a";
    //NSLog(@"path: %@", path);
//    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"is-in-queue"];
  
   // NSDictionary *dict = @{@"artistName": @"Chiddy Bang", @"composerName": @"Dr science", @"copyright": @"2016 YESSIR Inc.", @"description": @"YTBrowserHelper", @"download-id": @"5th.m4a", @"duration": @200295, @"genre": @"Music", @"kind": @"song", @"longDescription": @"probably some kind of science", @"playlistName": @"Breakfast", @"purchaseDate": [NSDate date], @"softwareVersionBundleId": @"com.ouraigua.ios.itunesimporter", @"title": @"5th quarter", @"trackNumber": @15, @"unmodified-title": @"5th quarter", @"year": @2016};
    /*
     
     artistName = "Chiddy Bang";
	    composerName = "Safari Downloader+";
	    copyright = "\U00a9 2015 Safari Downloader+";
	    description = "\U00a9 2015 Safari Downloader+";
	    "download-id" = "4th.m4a";
	    duration = 200295;
	    genre = Music;
	    kind = song;
	    longDescription = "Imported using Safari Downloader+. \U00a9 2015";
	    playlistName = Breakfast;
	    purchaseDate = "2016-01-04 04:58:38 +0000";
	    softwareVersionBundleId = "com.ouraigua.ios.itunesimporter";
	    title = "4th Quarter";
	    trackNumber = 14;
	    "unmodified-title" = "4th Quarter";
	    year = 2016;
     
     
     */
    
    // Pre-initialize metadata with required defaults
    //SSDownloadMetadata *metad = [[SSDownloadMetadata alloc] initWithDictionary:dict];
    SSDownloadMetadata *metad = [[SSDownloadMetadata alloc] initWithKind:@"song"];
    [metad setPrimaryAssetURL:[NSURL URLWithString:path]];
    
    /*[metad setCopyright:@"This song was added to iPod using libipodimport by H2CO3."];
    [metad setPurchaseDate:[NSDate date]]; // now
    //[metad setViewStoreItemURL:[NSURL URLWithString:@"http://twitter.com/H2CO3_iOS"]];
    //[metad setPrimaryAssetURL:[NSURL fileURLWithPath:path]];
    [metad setReleaseDate:[NSDate date]]; // now
    
    [metad setKind:@"song"];
    [metad setTitle:@"All of the lights2"]; // NSString
    [metad setArtistName:@"Childish Gambinos"]; // NSString
    [metad setCollectionName:@"None"]; // NSString
    [metad setGenre:@"Hip-Hop"]; // NSString
    [metad setDurationInMilliseconds:[NSNumber numberWithInt:237000]]; // NSNumber, int
    [metad setReleaseYear:[NSNumber numberWithInt:2015]]; // NSNumber, int
    */
    SSDownloadQueue *dlQueue = [[SSDownloadQueue alloc] initWithDownloadKinds:[SSDownloadQueue mediaDownloadKinds]];
    SSDownload *downl = [[SSDownload alloc] initWithDownloadMetadata:metad];
    
    [downl setDownloadHandler:nil completionBlock:^{
        NSLog(@"complete??");
      
        SSDownloadStatus *status = [downl status];
        NSLog(@"download: %@", downl);
        NSLog(@"status: %f", [status percentComplete]);
        NSLog(@"dlQueue: %@", dlQueue);
        
      //  SSDownloadManager *manager = [dlQueue downloadManager];
        //NSLog(@"manager activeDOwnloads: %@", [manager activeDownloads]);
        //NSLog(@"manager downloads: %@", [manager downloads]);
        BOOL failed = [status isFailed];
        if (failed == true)
        {
            NSLog(@"failed: %@", [status error]);
        }
       
        //    [dlQueue release];
    }];
    
    [dlQueue addDownload:downl];
    
}



@end

