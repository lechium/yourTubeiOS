//
//  KBYTDownloadManager.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/4/16.
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "KBYTDownloadOperation.h"

@interface KBYTDownloadManager : NSObject



+ (id)sharedInstance;
- (void)removeDownloadFromQueue:(NSDictionary *)downloadInfo;
- (void)addDownloadToQueue:(NSDictionary *)downloadInfo;
- (void)clearDownload:(NSDictionary *)streamDictionary;
- (void)updateDownloadsProgress:(NSDictionary *)streamDictionary;
@end
