//
//  KBYTGenericVideoTableViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/1/16.
//
//

#import <UIKit/UIKit.h>
#import "MarqueeLabel/MarqueeLabel.h"
#import "KBYTDownloadCell.h"
#import "KBYTPreferences.h"
#import "KBYourTube.h"

#define kGenericLoadingCellTag 600

@interface KBYTGenericVideoTableViewController : UITableViewController

@property (readwrite, assign) NSInteger tableType;

@property (nonatomic, strong) NSTimer *airplayTimer;
@property (nonatomic, strong) NSString *airplayIP;
#if TARGET_OS_IOS
@property (nonatomic, strong) UISlider *airplaySlider;
#endif
@property (nonatomic, strong) UIView *sliderView;
@property (readwrite, assign) CGFloat airplayProgressPercent;
@property (readwrite, assign) CGFloat airplayDuration;
@property (readwrite, assign) NSInteger currentPage;
@property (nonatomic, strong) NSString *customTitle;
@property (nonatomic, strong) NSString *customId;
@property (nonatomic, strong) NSString *nextHREF;

@property (nonatomic, strong) KBYTMedia *ytMedia;
@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) NSMutableArray *currentPlaybackArray;

- (id)initForType:(NSInteger)detailsType;
- (id)initForType:(NSInteger)detailsType withTitle:(NSString *)theTitle withId:(NSString *)identifier;

@end
