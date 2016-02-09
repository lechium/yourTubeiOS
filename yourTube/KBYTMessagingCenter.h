//
//  KBYTMessagingCenter.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

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
