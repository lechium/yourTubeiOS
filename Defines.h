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
#import "NSDictionary+serialize.h"
#import "NSObject+Additions.h"
#import "UIView+AL.h"
#import "../PureLayout/PureLayout.h"
#import "NSURLRequest+cURL.h"

#define INFINITE_CELL_COUNT 100000

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 0.5
#define kAnimationTranslateX 1.0
#define kAnimationTranslateY 1.0

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define TLog(format, ...) DLog(@"[tuyu] %@", [NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        TLog(@"%@ %@", self, NSStringFromSelector(_cmd))
#define LOG_CMD         TLog(@"[%@ %@]",[self class], NSStringFromSelector(_cmd))
#define DLOG_SELF DLog(@"%@ %@", self, NSStringFromSelector(_cmd))
#define FANCY_BYTES(B) [NSByteCountFormatter stringFromByteCount:B countStyle:NSByteCountFormatterCountStyleFile]

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

static NSString * const KBYTHomeDataChangedNotification = @"KBYTHomeDataChangedNotification";
static NSString * const KBYTUserDataChangedNotification = @"KBYTUserDataChangedNotification";

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
