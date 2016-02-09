//
//  YTDownloadOperation.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import <Foundation/Foundation.h>
#import "yourTube/Download/URLDownloader.h"
#import "YTBrowserHelper.h"

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
