//
//  KBYTMessagingCenter.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import "KBYTMessagingCenter.h"
#import "yourTubeApplication.h"
#import <UIKit/UIKit.h>

@implementation KBYTMessagingCenter

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static KBYTMessagingCenter *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            shared = [KBYTMessagingCenter new];
            
        });
    }
    
    return shared;
    
}

- (void)registerDownloadListener
{
    [[self downloadCenter] registerForMessageName:@"org.nito.dllistener.currentProgress" target:self selector:@selector(handleMessageName:userInfo:)];
    [[self downloadCenter] registerForMessageName:@"org.nito.dllistener.audioImported" target:self selector:@selector(handleMessageName:userInfo:)];
}

- (NSDictionary *)handleMessageName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    yourTubeApplication *appDelegate = (yourTubeApplication *)[[UIApplication sharedApplication] delegate];
    /*
     messageName: org.nito.dllistener.currentProgress userINfo: {
	    completionPercent = "0.1337406";
	    file = "Lil Wayne - Hollyweezy (Official Music Video) [720p].mp4";
     
     */
    if ([name.pathExtension isEqualToString:@"currentProgress"])
    {
        CGFloat progress = [userInfo[@"completionPercent"] floatValue];
        if (progress == 1.0)
        {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            NSString *file = userInfo[@"file"];
            if ([[file pathExtension] isEqualToString:@"aac"])
            {
              //skip the reload
            } else {
                if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
                {
                    [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] delayedReloadData];
                }
            }
            
            
        } else {
            if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
            {
                [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] updateDownloadProgress:userInfo];
            }
            
        }
        
    } else if ([[name pathExtension] isEqualToString:@"audioImported"])
    {
        NSString *file = userInfo[@"file"];
        NSString *messageString = [NSString stringWithFormat:@"The file %@ has been successfully imported into your iTunes library under the album name tuyu downloads.", file];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Audio import complete" message:messageString delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
        {
            [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] delayedReloadData];
        }
    }
    return nil;
}

- (void)startDownloadListener
{
    [[self downloadCenter] runServerOnCurrentThread];
}

- (void)stopDownloadListener
{
    [[self downloadCenter] stopServer];
}

- (void)addDownload:(NSDictionary *)streamDict
{
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTAddDownloadMessage] userInfo:streamDict];
}

- (void)stopDownload:(NSDictionary *)dictionaryMedia
{
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTStopDownloadMessage] userInfo:dictionaryMedia];
}

- (CPDistributedMessagingCenter *)downloadCenter
{
    return [CPDistributedMessagingCenter centerNamed:@"org.nito.dllistener"];
}

- (CPDistributedMessagingCenter *)center
{
    return [CPDistributedMessagingCenter centerNamed:KBYTMessageIdentifier];
}


- (void)airplayStream:(NSString *)stream ToDeviceIP:(NSString *)deviceIP
{
    NSDictionary *info = @{@"deviceIP": deviceIP, @"videoURL": stream};
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTStartAirplayMessage] userInfo:info];
}

- (void)pauseAirplay
{
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTPauseAirplayMessage] userInfo:nil];
}

- (void)stopAirplay
{
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTStartAirplayMessage] userInfo:nil];
}

- (NSInteger)airplayStatus
{
    NSDictionary *response = [[self center] sendMessageAndReceiveReplyName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTAirplayStateMessage] userInfo:nil];
    // NSLog(@"response: %@", response);
    return [[response valueForKey:@"playbackState"] integerValue];
}



@end
