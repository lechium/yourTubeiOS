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


@interface KBYTGenericVideoTableViewController : UITableViewController

@property (readwrite, assign) NSInteger tableType;

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
@property (readwrite, assign) NSInteger currentPage;
@property (nonatomic, strong) NSString *lastSearch;
@property (readwrite, assign) BOOL showingSuggestedVideos;

- (id)initForType:(NSInteger)detailsType;

@end
