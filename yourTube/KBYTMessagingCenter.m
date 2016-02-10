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
    /*
     messages for download progress are relayed through current progress messages to track download percentage
    and download completion
   */
     [[self downloadCenter] registerForMessageName:[KBYTDownloadIdentifier stringByAppendingPathExtension:KBYTDownloadProgressMessage] target:self selector:@selector(handleMessageName:userInfo:)];
    
    /* since audio needs to be run through ffmpeg and JODebox need an additional message to listen for import completion
    */
    
     [[self downloadCenter] registerForMessageName:[KBYTDownloadIdentifier stringByAppendingPathExtension:KBYTAudioImportFinishedMessage] target:self selector:@selector(handleMessageName:userInfo:)];
}

/**
 
 All messages sent from YTBrowser tweak regarding download status and audio import completion are routed
 through this method.
 
 
 */

- (NSDictionary *)handleMessageName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    //easiest way to get at the top/visible view controller without another property/ivar is to reference delegate
    yourTubeApplication *appDelegate = (yourTubeApplication *)[[UIApplication sharedApplication] delegate];
    /*
     messageName: org.nito.dllistener.currentProgress userINfo: {
	    completionPercent = "0.1337406";
	    file = "Lil Wayne - Hollyweezy (Official Music Video) [720p].mp4";
     
     */
    if ([name.pathExtension isEqualToString:KBYTDownloadProgressMessage])
    {
        CGFloat progress = [userInfo[@"completionPercent"] floatValue];
        if (progress == 1.0) //download is complete at 1.0
        {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            NSString *file = userInfo[@"file"];
            if ([[file pathExtension] isEqualToString:@"aac"])
            {
              //skip the reload for audio otherwise indeterminate progress bars dont work upon reload.
            } else {
                //video downloads, reload the table view on a delay.
                if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
                {
                    [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] delayedReloadData];
                }
            }
            
            
        } else { //still downloading
            
            if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
            {
                [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] updateDownloadProgress:userInfo];
            }
            
        }
        
    } else if ([[name pathExtension] isEqualToString:KBYTAudioImportFinishedMessage]) //audio import is complete!
    {
        NSString *file = userInfo[@"file"];
        NSString *messageString = [NSString stringWithFormat:@"The file %@ has been successfully imported into your iTunes library under the album name tuyu downloads.", file];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Audio import complete" message:messageString delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        //reload the table view!
        if ([[[appDelegate nav] visibleViewController] isKindOfClass:[KBYTDownloadsTableViewController class]])
        {
            [(KBYTDownloadsTableViewController*)[[appDelegate nav] visibleViewController] delayedReloadData];
        }
    }
    return nil;
}

//kicks off the downloadlistener so we can receive messages about download progress
- (void)startDownloadListener
{
    [[self downloadCenter] runServerOnCurrentThread];
}

//shuts the listener down, if this isnt done with the App is inactive EVERYTHING goes haywire.
- (void)stopDownloadListener
{
    [[self downloadCenter] stopServer];
}

//send a message to our tweak to add a new download
- (void)addDownload:(NSDictionary *)streamDict
{
    LOG_SELF;
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTAddDownloadMessage] userInfo:streamDict];
}

//send a message to cancel a download that is currently in progress
- (void)stopDownload:(NSDictionary *)dictionaryMedia
{
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTStopDownloadMessage] userInfo:dictionaryMedia];
}

//the center for download progress / audio import completion
- (CPDistributedMessagingCenter *)downloadCenter
{
    return [CPDistributedMessagingCenter centerNamed:KBYTDownloadIdentifier];
}


//the center we use to send messages to start/stop downloads and airplay
- (CPDistributedMessagingCenter *)center
{
    return [CPDistributedMessagingCenter centerNamed:KBYTMessageIdentifier];
}

//receives a URL in string format and a deviceIP to play the stream on via AirPlay
- (void)airplayStream:(NSString *)stream ToDeviceIP:(NSString *)deviceIP
{
    NSDictionary *info = @{@"deviceIP": deviceIP, @"videoURL": stream};
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTStartAirplayMessage] userInfo:info];
}

//pause current airplay stream
- (void)pauseAirplay
{
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTPauseAirplayMessage] userInfo:nil];
}

//stop current airplay stream
- (void)stopAirplay
{
    [[self center] sendMessageName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTStopAirplayMessage] userInfo:nil];
}

//find out if there are any airplay streams currently active
- (NSInteger)airplayStatus
{
    NSDictionary *response = [[self center] sendMessageAndReceiveReplyName:[KBYTMessageIdentifier stringByAppendingPathExtension:KBYTAirplayStateMessage] userInfo:nil];
    // NSLog(@"response: %@", response);
    return [[response valueForKey:@"playbackState"] integerValue];
}



@end
