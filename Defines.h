//
//  Defines.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import "AppSupport/CPDistributedMessagingCenter.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "KBYourTube+Categories.h"
#import "PureLayout.h"

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        NSLog(@"%@ %@", self, NSStringFromSelector(_cmd))

static NSString *const KBYTMessageIdentifier   =  @"org.nito.importscience";
static NSString *const KBYTDownloadIdentifier  =  @"org.nito.dllistener";

static NSString *const KBYTPauseAirplayMessage =  @"pauseAirplay";
static NSString *const KBYTStopAirplayMessage  =  @"stopAirplay";
static NSString *const KBYTStartAirplayMessage =  @"startAirplay";
static NSString *const KBYTAirplayStateMessage =  @"airplayState";

static NSString *const KBYTAddDownloadMessage  =  @"addDownload";
static NSString *const KBYTStopDownloadMessage =  @"stopDownload";

static NSString *const KBYTDownloadProgressMessage    = @"currentProgress";
static NSString *const KBYTAudioImportFinishedMessage = @"audioImported";

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)