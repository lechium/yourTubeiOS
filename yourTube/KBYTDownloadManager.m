//
//  KBYTDownloadManager.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/4/16.
//
//

#import "KBYTDownloadManager.h"


@interface KBYTDownloadManager ()

@property (strong, nonatomic) NSOperationQueue      *operationQueue;
@property (nonatomic, strong)                       NSMutableArray *operations;

@end

@implementation KBYTDownloadManager


- (void)removeDownloadFromQueue:(NSDictionary *)downloadInfo
{
    for (KBYTDownloadOperation *operation in [self operations])
    {
        if ([[operation name] isEqualToString:downloadInfo[@"title"]])
        {
            NSLog(@"found operation, cancel it!");
            [operation cancel];
        }
    }
    [self clearDownload:downloadInfo];
}

//add a download to our NSOperationQueue

- (void)addDownloadToQueue:(NSDictionary *)downloadInfo
{
    KBYTDownloadOperation *downloadOp = [[KBYTDownloadOperation alloc] initWithInfo:downloadInfo completed:^(NSString *downloadedFile) {
        
        if (downloadedFile == nil)
        {
            NSLog(@"no downloaded file, either cancelled or failed!");
            return;
        }
        if (![[downloadedFile pathExtension] isEqualToString:[downloadInfo[@"outputFilename"] pathExtension]])
        {
            NSMutableDictionary *mutableCopy = [downloadInfo mutableCopy];
            [mutableCopy setValue:[downloadedFile lastPathComponent] forKey:@"outputFilename"];
            [mutableCopy setValue:[NSNumber numberWithBool:false] forKey:@"inProgress"];
            [self updateDownloadsProgress:mutableCopy];
        } else {
            [self updateDownloadsProgress:downloadInfo];
        }
        
        NSLog(@"download completed!");
        [[self operations] removeObject:downloadOp];
        [self playCompleteSound];
        
    }];
    [[self operations] addObject:downloadOp];
    
    [self.operationQueue addOperation:downloadOp];
    if ([downloadOp isExecuting])
    {
    } else {
        [downloadOp main];
    }
}

- (void)clearDownload:(NSDictionary *)streamDictionary
{
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *dlplist = [self downloadFile];
    NSMutableArray *currentArray = nil;
    if ([man fileExistsAtPath:dlplist])
    {
        currentArray = [[NSMutableArray alloc] initWithContentsOfFile:dlplist];
        NSMutableDictionary *updateObject = [[currentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.title == %@", streamDictionary[@"title"]]]lastObject];
        NSInteger objectIndex = [currentArray indexOfObject:updateObject];
        if (objectIndex != NSNotFound)
        {
            [currentArray removeObject:updateObject];
        }
        
    } else {
        currentArray = [NSMutableArray new];
    }
    //[currentArray addObject:streamDictionary];
    [currentArray writeToFile:dlplist atomically:true];
}

//update download progress of whether or not a file is inProgress or not, used to separate downloads in
//UI of tuyu downloads section.

- (void)updateDownloadsProgress:(NSDictionary *)streamDictionary
{
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *dlplist = [self downloadFile];
    NSMutableArray *currentArray = nil;
    if ([man fileExistsAtPath:dlplist])
    {
        currentArray = [[NSMutableArray alloc] initWithContentsOfFile:dlplist];
        NSMutableDictionary *updateObject = [[currentArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.title == %@", streamDictionary[@"title"]]]lastObject];
        NSInteger objectIndex = [currentArray indexOfObject:updateObject];
        if (objectIndex != NSNotFound)
        {
            if ([[streamDictionary[@"outputFilename"]pathExtension] isEqualToString:@"m4a"])
            {
                [currentArray replaceObjectAtIndex:objectIndex withObject:streamDictionary];
                // [currentArray removeObject:updateObject];
                
            } else {
                [updateObject setValue:[NSNumber numberWithBool:false] forKey:@"inProgress"];
                [currentArray replaceObjectAtIndex:objectIndex withObject:updateObject];
                
            }
        }
        
    } else {
        currentArray = [NSMutableArray new];
    }
    //[currentArray addObject:streamDictionary];
    [currentArray writeToFile:dlplist atomically:true];
}

//standard tri-tone completion sound

- (void)playCompleteSound
{
   // NSString *thePath = @"/Applications/yourTube.app/complete.aif";
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"complete" ofType:@"aif"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: thePath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static KBYTDownloadManager *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            shared = [KBYTDownloadManager new];
            shared.operationQueue = [NSOperationQueue mainQueue];
            shared.operationQueue.name = @"Connection Queue";
            shared.operations = [NSMutableArray new];
        });
    }
    
    return shared;
    
}

@end
