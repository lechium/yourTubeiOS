//
//  KBYTMessagingCenter.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

/**
 
 This class handles all of the communication between the YTBrowser.xm mobile substrate tweak and the
 yourTube/tuyu application. Starting/stopping downloads, relaying download progress and airplay is
 all handled through this class.
 
 */

#import <Foundation/Foundation.h>
#import "KBYourTube.h"

@interface KBYTMessagingCenter : NSObject

+ (id)sharedInstance;
- (CPDistributedMessagingCenter *)center;
- (void)pauseAirplay;
- (void)stopAirplay;
- (NSInteger)airplayStatus;
- (void)airplayStream:(NSString *)stream ToDeviceIP:(NSString *)deviceIP;
- (void)stopDownload:(NSDictionary *)dictionaryMedia;
- (void)addDownload:(NSDictionary *)streamDict;
- (void)stopDownloadListener;
- (void)startDownloadListener;
- (void)registerDownloadListener;
@end
