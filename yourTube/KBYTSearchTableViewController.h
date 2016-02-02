//
//  KBYTSearchTableViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/1/16.
//
//

#import <UIKit/UIKit.h>
#import "MarqueeLabel/MarqueeLabel.h"
#import "KBYTDownloadsTableViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "KBYTPreferences.h"
#import "KBYourTube.h"

@interface YTKBPlayerViewController : AVPlayerViewController

@end

@protocol KBYTSearchTableViewControllerDelegate <NSObject>

- (void)pushViewController:(id)controller;

@end

@interface KBYTSearchTableViewController : UITableViewController
{
    id <KBYTSearchTableViewControllerDelegate> __weak delegate;
}
@property (nonatomic, weak) id<KBYTSearchTableViewControllerDelegate> delegate;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) KBYTMedia *currentMedia;
@property (nonatomic, strong) NSString *previousVideoID;
@property (readwrite, assign) BOOL gettingDetails;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSTimer *airplayTimer;
@property (nonatomic, strong) NSString *airplayIP;
@property (nonatomic, strong) UISlider *airplaySlider;
@property (nonatomic, strong) UIView *sliderView;
@property (readwrite, assign) CGFloat airplayProgressPercent;
@property (readwrite, assign) CGFloat airplayDuration;

- (void)playFile:(NSDictionary *)file;
- (void)getVideoIDDetails:(NSString *)details;
@end
