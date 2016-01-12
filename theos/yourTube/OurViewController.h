//
//  ViewController.h
//  yourMusic
//
//  Created by Kevin Bradley on 1/8/16.
//  Copyright © 2016 nito. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>
#import "KBYourTube.h"
#import "KBYTDownloadStream.h"
#import "URLDownloader.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
//#import "KBYTDownloadStream.h"

@protocol OurViewControllerDelegate <NSObject>

- (void)pushViewController:(id)controller;

@end

@interface OurViewController : UIViewController <WKNavigationDelegate, URLDownloaderDelegate, UIActionSheetDelegate, WKScriptMessageHandler>
{
    id <OurViewControllerDelegate> __weak delegate;
}
@property (nonatomic, weak) id<OurViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet WKWebView *webView;

//@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (retain) URLDownloader *downloader;
@property (nonatomic, strong) KBYTDownloadStream *downloadFile;
@property (readwrite, assign) BOOL downloading;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerViewController *playerView;

@property (nonatomic, strong) KBYTMedia *currentMedia;
@property (readwrite, assign) BOOL gettingDetails;
//@property (nonatomic, assign) IBOutlet AVPlayerView *playerView;
@end

