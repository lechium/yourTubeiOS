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

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        NSLog(@"%@ %@", self, NSStringFromSelector(_cmd))

static NSString *const KBYTMessageIdentifier   =  @"org.nito.importscience";

static NSString *const KBYTPauseAirplayMessage =  @"pauseAirplay";
static NSString *const KBYTStopAirplayMessage  =  @"stopAirplay";
static NSString *const KBYTStartAirplayMessage =  @"startAirplay";
static NSString *const KBYTAirplayStateMessage =  @"airplayState";


static NSString *const KBYTAddDownloadMessage  =  @"addDownload";
static NSString *const KBYTStopDownloadMessage =  @"stopDownload";
